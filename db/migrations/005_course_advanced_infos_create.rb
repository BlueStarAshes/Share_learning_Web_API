# frozen_string_literal: true
require 'sequel'

Sequel.migration do
  change do
    create_table(:course_advanced_infos) do
      # primary_key [:course_id, :advanced_info_id], name: :items_pk
      primary_key  :id
      foreign_key :course_id
      foreign_key :advanced_info_id
      String :time
    end
  end
end
