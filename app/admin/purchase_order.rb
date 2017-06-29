ActiveAdmin.register PurchaseOrder do

# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

form do |f|
    f.inputs "PurchaseOrder Details" do
      f.input :_id
      f.input :client
      f.input :supplier
      f.input :sku
      f.date_field :delivery_date
      f.input :amount
      f.input :delivered_qt
      f.input :unit_price
      f.input :channel
      f.input :status
      f.input :notes
      f.input :rejection
      f.input :anullment
      f.input :direccion
    end
    f.actions
  end

permit_params :_id, :client, :supplier, :sku,:delivery_date,:amount,:delivered_qt,:unit_price,:channel,:status,:notes,:rejection,:anullment,:direccion

end
