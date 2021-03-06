# frozen_string_literal: true
require 'sequel'

Sequel.migration do
  change do
    create_table(:reviews) do
      primary_key :id
      String :content
      String :created_time
    end
  end
end
