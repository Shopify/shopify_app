module HomeHelper

  def customer_name(order)
    name = ''
    name += [order.customer.first_name, order.customer.last_name].join(" ") if order.respond_to?(:customer)
    name.strip
  end

end