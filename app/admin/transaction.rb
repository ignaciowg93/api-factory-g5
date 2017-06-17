ActiveAdmin.register Transaction do
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
    f.inputs "Transaction Details" do
      f.input :_id
      f.input :origin
      f.input :destiny
      f.input :amount
      f.check_box :state
    end
    f.actions
  end

permit_params :_id, :origin,:destiny,:amount ,:state

end
