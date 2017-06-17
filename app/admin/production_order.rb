ActiveAdmin.register ProductionOrder do
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
    f.inputs "ProductionOrder Details" do
      f.input :oc_id
      f.input :sku
      f.input :amount
      f.select_date :est_date
    end
    f.actions
  end

permit_params  :sku,:amount,:oc_id, :est_date

end
