class <%= @service_class_name %> < Struct.new(:params)
  def self.fetch_stock(*args)
    new(*args).fetch_stock
  end

  def self.fetch_tracking_numbers(*args)
    new(*args).fetch_tracking_numbers
  end

  def fetch_stock
    # fulfillment service stock lookup goes here
    if params[:sku].present?
      { params[:sku] => 0 }
    else
      {'123' => 1000, '456' => 500}
    end
  end

  def fetch_tracking_numbers
    # fulfillment service tracking_number lookup goes here
    {}
  end
end
