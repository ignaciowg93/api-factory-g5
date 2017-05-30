# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170516230539) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "clients", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "token"
    t.string   "gnumber"
  end

  create_table "factories", force: :cascade do |t|
    t.integer  "status"
    t.boolean  "busy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_regs", force: :cascade do |t|
    t.string   "oc_id"
    t.integer  "status"
    t.integer  "delivered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "invoiceid"
    t.boolean  "accepted"
    t.boolean  "rejected"
    t.boolean  "delivered"
    t.boolean  "paid"
    t.string   "account"
    t.integer  "price"
    t.integer  "tax"
    t.integer  "total_price"
    t.string   "proveedor"
    t.string   "cliente"
    t.datetime "date"
    t.string   "po_idtemp"
  end

  create_table "messages", force: :cascade do |t|
    t.string   "content"
    t.string   "name"
    t.integer  "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_messages_on_client_id", using: :btree
  end

  create_table "products", force: :cascade do |t|
    t.string   "sku"
    t.string   "name"
    t.decimal  "price",        precision: 64, scale: 12
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "warehouse_id"
    t.integer  "processed"
    t.integer  "lot"
    t.integer  "ingredients"
    t.integer  "dependent"
    t.decimal  "time"
    t.integer  "stock_reservado"
    t.index ["warehouse_id"], name: "index_products_on_warehouse_id", using: :btree
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string   "_id"
    t.string   "client"
    t.string   "supplier"
    t.string   "sku"
    t.datetime "delivery_date"
    t.integer  "amount"
    t.integer  "delivered_qt"
    t.integer  "unit_price"
    t.string   "channel"
    t.string   "status"
    t.string   "notes"
    t.string   "rejection"
    t.string   "anullment"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "stocks", force: :cascade do |t|
    t.string   "sku"
    t.integer  "totalAmount"
    t.integer  "selledAmount"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "supplies", force: :cascade do |t|
    t.string   "sku"
    t.integer  "requierment"
    t.integer  "stock_reservado"
    t.decimal  "time"
    t.integer  "product_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["product_id"], name: "index_supplies_on_product_id", using: :btree
  end

  create_table "sellers", force: :cascade do |t|
    t.integer   "supply_id"
    t.string   "seller"
    t.decimal  "time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.integer  "type"
    t.integer  "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "messages", "clients"
  add_foreign_key "products", "warehouses"
  add_foreign_key "supplies", "products"
end
