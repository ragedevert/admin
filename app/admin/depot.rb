ActiveAdmin.register Depot do
  menu parent: :other, priority: 10

  scope :all
  scope :visible, default: true
  scope :hidden

  includes :memberships, :responsible_member
  index do
    column :name, ->(d) { auto_link d }
    column :address
    column :zip
    column :city
    column :visible
    if Depot.pluck(:price).any?(&:positive?)
      column :price, ->(d) { cur(d.price) }
    end
    column :deliveries_count, ->(d) {
      link_to d.deliveries_count, deliveries_path(
        q: {
          depots_id_eq: d.id,
          during_year: Current.acp.current_fiscal_year.year
        },
        scope: :all)
    }
    column :responsible_member
    actions class: 'col-actions-3'
  end

  csv do
    column(:id)
    column(:name)
    if Current.acp.languages.many?
      row(:language) { |d| t("languages.#{d.language}") }
    end
    column(:price) { |d| cur(d.price) }
    column(:note)
    column(:address_name)
    column(:address)
    column(:zip)
    column(:visible)
    column(:emails) { |d| d.emails_array.join(', ') }
    column(:phones) { |d| d.phones_array.map(&:phony_formatted).join(', ') }
    column(:responsible_member) { |d| d.responsible_member&.name }
    column(:responsible_member_emails) { |d|
      d.responsible_member&.emails_array&.join(', ')
    }
    column(:responsible_member_phones) { |d|
      d.responsible_member&.phones_array&.map(&:phony_formatted)&.join(', ')
    }
  end

  show do |depot|
    columns do
      column do
        if depot.deliveries.current_year.any?
          panel Depot.human_attribute_name(:current_deliveries) do
            table_for depot.deliveries.current_year, class: 'deliveries' do
              column '#', ->(d) { auto_link d, d.number }
              column :date, ->(d) { auto_link d, l(d.date) }
            end
          end
        end
        if depot.deliveries.future_year.any?
          panel Depot.human_attribute_name(:future_deliveries) do
            table_for depot.deliveries.future_year, class: 'deliveries' do
              column '#', ->(d) { auto_link d, d.number }
              column :date, ->(d) { auto_link d, l(d.date) }
            end
          end
        end
      end
      column do
        attributes_table do
          row :id
          row :name
          if Current.acp.languages.many?
            row(:language) { t("languages.#{depot.language}") }
          end
          row(:price) { cur(depot.price) }
          row(:deliveries_count) {
            link_to(
              depot.deliveries_count,
              deliveries_path(q: { depots_id_eq: depot.id }))
          }
          row(:visible)
          row(:note) { text_format(depot.note) }
        end

        attributes_table title: t('.member_new_form') do
          row :form_name
          row :form_priority
        end

        attributes_table title: Depot.human_attribute_name(:address) do
          row :address_name
          row :address
          row :zip
          row :city
        end

        attributes_table title: Depot.human_attribute_name(:contact) do
          row(:emails) { display_emails_with_link(self, depot.emails_array) }
          row(:phones) { display_phones_with_link(self, depot.phones_array) }
          row :responsible_member
        end

        active_admin_comments
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      language_input(f)
      f.input :price, hint: true
      f.input :visible, as: :select, hint: true, prompt: true, required: true
      f.input :note, input_html: { rows: 3 }
    end

    f.inputs t('active_admin.resource.show.member_new_form') do
      translated_input(f, :form_names,
        required: false,
        hint: t('formtastic.hints.depot.form_name'))
      f.input :form_priority, hint: true
    end

    f.inputs Depot.human_attribute_name(:address) do
      f.input :address_name
      f.input :address
      f.input :city
      f.input :zip
    end

    f.inputs Depot.human_attribute_name(:contact) do
      f.input :emails, as: :string
      f.input :phones, as: :string
      f.input :responsible_member, collection: Member.order(:name)
    end

    f.inputs do
      if Delivery.current_year.any?
        f.input :current_deliveries,
          as: :check_boxes,
          collection: Delivery.current_year,
          hint: f.object.persisted?,
          input_html: f.object.persisted? ? {} : { checked: true }
      end
      if Delivery.future_year.any?
        f.input :future_deliveries,
          as: :check_boxes,
          collection: Delivery.future_year,
          hint: f.object.persisted?,
          input_html: f.object.persisted? ? {} : { checked: true }
      end
    end

    f.actions
  end

  permit_params(
    *%i[
      name language price visible note
      address_name address zip city
      emails phones responsible_member_id
      form_priority
    ],
    *I18n.available_locales.map { |l| "form_name_#{l}" },
    current_delivery_ids: [],
    future_delivery_ids: [])

  before_build do |depot|
    depot.price ||= 0.0
  end

  controller do
    include TranslatedCSVFilename
  end

  config.filters = false
  config.per_page = 25
  config.sort_order = 'name_asc'
end
