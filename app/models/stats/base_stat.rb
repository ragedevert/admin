class Stats::BaseStat
  def self.all
    raise NotImplementedError
  end

  attr_reader :year

  def initialize(year)
    @year = year
  end

  private

  def memberships(includes: [])
    by_user = Membership.includes(*includes).duration_gt(60).during_year(year).to_a.group_by(&:member_id)
    by_user.map { |_, memberships|
      memberships.max_by { |m| m.ended_on - m.started_on }
    }
  end
end
