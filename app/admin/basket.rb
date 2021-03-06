ActiveAdmin.register Basket do
  menu false
  actions :edit, :update

  breadcrumb do
    links = [
      link_to(Member.model_name.human(count: 2), members_path),
      auto_link(basket.membership.member),
      link_to(
        Membership.model_name.human(count: 2),
        memberships_path(q: { member_id_eq: basket.membership.member_id }, scope: :all)),
      auto_link(basket.membership)
    ]
    if params['action'].in? %W[edit]
      links << [Basket.model_name.human, basket.delivery.display_name(format: :number)].join(' ')
    end
    links
  end

  form do |f|
    f.inputs do
      f.input :basket_size, prompt: true, input_html: { class: 'js-reset_price' }
      f.input :basket_price, hint: true, required: false
      f.input :quantity
      delivery_collection = basket_deliveries_collection(f.object)
      if delivery_collection.many?
        f.input :delivery,
          collection: delivery_collection,
          prompt: true,
          input_html: { class: 'js-update_basket_depot_options' }
      end
      f.input :depot,
        collection: basket_depots_collection(f.object),
        prompt: true,
        input_html: { class: 'js-reset_price' }
      f.input :depot_price, hint: true, required: false
      if BasketComplement.any?
        f.has_many :baskets_basket_complements, allow_destroy: true do |ff|
          ff.input :basket_complement,
            collection: BasketComplement.all,
            prompt: true,
            input_html: { class: 'js-reset_price' }
          ff.input :price, hint: true, required: false
          ff.input :quantity
        end
      end
    end
    f.actions do
      f.action :submit, as: :input
      cancel_link membership_path(f.object.membership)
    end
  end

  permit_params \
    :basket_size_id, :basket_price, :quantity,
    :delivery_id,
    :depot_id, :depot_price,
    baskets_basket_complements_attributes: %i[
      id basket_complement_id
      price quantity
      _destroy
    ]

  controller do
    include TranslatedCSVFilename

    def update
      super do
        redirect_to resource.membership and return if resource.valid?
      end
    end
  end
end
