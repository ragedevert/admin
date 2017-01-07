class HalfdayWork < ActiveRecord::Base
  MEMBER_PER_YEAR = 2
  PERIODS = %w[am pm].freeze
  PRICE = 60

  attr_reader :carpooling

  belongs_to :member
  belongs_to :validator, class_name: 'Admin'

  scope :status, ->(status) { send(status) }
  scope :validated, -> { where.not(validated_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :pending, -> do
    where('date <= ?', Time.zone.today).where(validated_at: nil, rejected_at: nil)
  end
  scope :coming, -> { where('date > ?', Time.zone.today) }
  scope :coming_for_member, -> { where('date >= ?', Time.zone.today) }
  scope :past, -> do
    where('date < ? AND date >= ?', Time.zone.today, Time.zone.today.beginning_of_year)
  end
  scope :during_year, ->(year) {
    where(
      'date >= ? AND date <= ?',
      Date.new(year).beginning_of_year,
      Date.new(year).end_of_year
    )
  }
  scope :carpooling, -> (date) { where(date: date).where.not(carpooling_phone: nil) }

  validates :member_id, :date, presence: true
  validate :periods_include_good_value
  validates :date,
    inclusion: { in: :available_dates },
    unless: :validated_at?
  validates :period_am, absence: { if: -> { available_periods.exclude?('am') } }
  validates :period_pm, absence: { if: -> { available_periods.exclude?('pm') } }
  validate :participants_limit_must_not_be_reached, unless: :validated_at?

  before_create :set_carpooling_phone
  after_update :send_notifications

  def status
    if validated_at?
      :validated
    elsif rejected_at?
      :rejected
    elsif date <= Time.zone.today
      :pending
    else
      :coming
    end
  end

  def state
    if validated_at?
      'validated'
    elsif rejected_at?
      'rejected'
    else
      'pending'
    end
  end

  %i[validated rejected pending coming].each do |status|
    define_method "#{status}?" do
      self.status == status
    end
  end

  def value
    periods.size * participants_count
  end

  def carpooling=(carpooling)
    @carpooling = carpooling == '1'
  end

  def carpooling?
    carpooling_phone
  end

  def validate!(validator)
    return if coming?
    update(rejected_at: nil, validated_at: Time.zone.now, validator_id: validator.id)
  end

  def reject!(validator)
    return if coming?
    update(rejected_at: Time.zone.now, validated_at: nil, validator_id: validator.id)
  end

  PERIODS.each do |period|
    define_method "period_#{period}" do
      periods.try(:include?, period)
    end
    define_method "#{period}?" do
      periods.try(:include?, period)
    end

    define_method "period_#{period}=" do |bool|
      periods_will_change!
      self.periods ||= []
      if bool.in? [1, '1']
        self.periods << period
        self.periods.uniq!
      else
        self.periods.delete(period)
      end
    end
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i(status)
  end

  def available_periods
    periods = HalfdayWorkDate.where(date: date).flat_map(&:periods).uniq
    periods.empty? ? PERIODS : periods
  end

  def available_dates
    HalfdayWorkDate.pluck(:date).uniq
  end

  private

  def periods_include_good_value
    if periods.blank? || !periods.all? { |d| d.in? PERIODS }
      errors.add(:periods, 'Sélectionner au moins un horaire, merci')
    end
  end

  def set_carpooling_phone
    if @carpooling
      if carpooling_phone.blank?
        self.carpooling_phone = member.phones_array.first
      end
    else
      self.carpooling_phone = nil
    end
  end

  def send_notifications
    if validated_at_changed? && validated_at?
      HalfdayMailer.validated(self).deliver_now
    end
    if rejected_at_changed? && rejected_at?
      HalfdayMailer.rejected(self).deliver_now
    end
  end

  def participants_limit_must_not_be_reached
    halfday_work_dates = HalfdayWorkDate.where(date: date)
    if halfday_work_dates.present? && (period_am || period_pm)
      am_limit_reached = halfday_work_dates.find(&:am?)&.am_full?
      pm_limit_reached = halfday_work_dates.find(&:pm?)&.pm_full?
      if am_limit_reached && pm_limit_reached
        errors.add(:periods, 'La journée est déjà complète, merci!')
      elsif period_am && am_limit_reached
        errors.add(:periods, 'Le matin est déjà complet, merci!')
      elsif period_pm && pm_limit_reached
        errors.add(:periods, "L'après-midi est déjà complète, merci!")
      end
    end
  end
end
