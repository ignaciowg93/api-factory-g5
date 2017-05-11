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

ActiveRecord::Schema.define(version: 20170427004647) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "token"
  end

  create_table "factories", force: :cascade do |t|
    t.integer  "status"
    t.boolean  "busy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoices", force: :cascade do |t|
    t.integer  "purchase_order_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "invoiceid"
    t.boolean  "accepted"
    t.boolean  "rejected"
    t.boolean  "delivered"
    t.boolean  "paid"
    t.string   "account"
    t.index ["purchase_order_id"], name: "index_invoices_on_purchase_order_id", using: :btree
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
    t.index ["warehouse_id"], name: "index_products_on_warehouse_id", using: :btree
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string   "payment_method"
    t.string   "payment_option"
    t.datetime "date"
    t.string   "sku"
    t.integer  "amount"
    t.string   "status"
    t.datetime "delivery_date"
    t.integer  "unit_price"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "poid"
    t.string   "rejection"
  end

  create_table "warehouses", force: :cascade do |t|
    t.integer  "type"
    t.integer  "capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "invoices", "purchase_orders"
  add_foreign_key "messages", "clients"
  add_foreign_key "products", "warehouses"
end
