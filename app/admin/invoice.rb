ActiveAdmin.register Invoice do
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



permit_params  :invoiceid,:accepted,:rejected,:delivered,:paid,:account,:price,:tax,:total_price,:proveedor,:cliente,:date,:po_idtemp, :boleta,:status,:amount,:sku
end
