# frozen_string_literal: true

class AddRegistrationFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string   :full_name, limit: 255
      t.boolean  :consent_accepted, null: false, default: false
      t.datetime :consent_timestamp
    end
  end
end
