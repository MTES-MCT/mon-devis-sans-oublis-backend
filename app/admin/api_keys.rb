# frozen_string_literal: true

ActiveAdmin.register_page "API Keys" do
  menu label: "API Keys", priority: 250

  content title: "API Keys" do
    panel "Liste des API Keys" do
      table_for Api::V1::ApiAccess.api_keys.to_a.sort_by(&:first) do
        column("Partenaire = Source") { |(k, _)| k }
        column("Clé") { |(_, v)| v }
      end
    end
  end
end
