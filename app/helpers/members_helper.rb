module MembersHelper
  def languages_collection
    Current.acp.languages.map { |l| [t("languages.#{l}"), l] }
  end

  def billing_year_divisions_collection
    Current.acp.billing_year_divisions.map { |i|
      [I18n.t("billing.year_division.x#{i}"), i]
    }
  end

  def basket_sizes_collection
    BasketSize.all.map { |bs|
      [
        collection_text(bs.name,
          price: price_info(bs.annual_price),
          details: [
            deliveries_count(bs.deliveries_count),
            halfdays_count(bs.annual_halfday_works)
          ].join(', ')),
        bs.id
      ]
    } << [
      collection_text(t('helpers.no_basket_size'),
        details: t('helpers.no_basket_size_details')),
      0
    ]
  end

  def basket_complements_collection
    BasketComplement.includes(:deliveries).map { |bc|
      [
        collection_text(bc.name,
          price: price_info(bc.annual_price, precision: 2),
          details: deliveries_count(bc.deliveries.size)),
        bc.id
      ]
    }
  end

  def distributions_collection
    Distribution.visible.reorder('price, name').map { |d|
      details = [d.address, "#{d.zip} #{d.city}".presence].compact.join(', ') if d.address?
      if details && details != d.address
        details += map_icon(details).html_safe
      end

      [
        collection_text(d.name,
          price: price_info(d.annual_price),
          details: details),
        d.id
      ]
    }
  end

  private

  def price_info(price, *options)
    number_to_currency(price, *options) if price.positive?
  end

  def collection_text(text, price: nil, details: nil)
    txts = [text]
    txts << "<em class='price'>#{price}</em>" if price
    txts << "<em>(#{details})</em>" if details.present?
    txts.join.html_safe
  end

  def map_icon(location)
    <<-TXT
      <a class='map' href="https://www.google.com/maps?q=#{location}" title="#{location}" target="_blank">
        <i class="fa fa-map-signs"></i>
      </a>
    TXT
  end

  def deliveries_count(count)
    "#{count}&nbsp;#{Delivery.model_name.human(count: count)}".downcase
  end

  def halfdays_count(count)
    t_halfday('helpers.halfdays_count_per_year', count: count).gsub(/\s/, '&nbsp;')
  end
end