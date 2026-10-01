# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration page", type: :request do
  let(:document) do
    get "/register.html"
    Nokogiri::HTML(response.body)
  end

  it "is served" do
    get "/register.html"
    expect(response).to have_http_status(:ok)
  end

  it "declares the document language and a title" do
    expect(document.at("html")["lang"]).to eq("en")
    expect(document.at("title").text).to be_present
  end

  it "renders the registration fields in logical focus order" do
    names = document.css("#registration-form input, #registration-form button").map { |el| el["name"] || el["type"] }
    expect(names).to eq(%w[full_name email_address password consent_accepted submit])
  end

  it "associates a visible label with every input" do
    document.css("#registration-form input").each do |input|
      label = document.at("label[for='#{input['id']}']")
      expect(label).to be_present, "missing label for ##{input['id']}"
      expect(label.text.strip).to be_present
    end
  end

  it "includes the ToS/privacy consent checkbox" do
    checkbox = document.at("input#consent_accepted")
    expect(checkbox["type"]).to eq("checkbox")
    expect(document.at("label[for='consent_accepted']").text).to match(/Terms of Service.*Privacy Policy/)
  end

  it "connects error messages to their inputs" do
    document.css("#registration-form input").each do |input|
      expect(input["aria-describedby"].to_s.split).to include("#{input['id']}-error")
      expect(document.at("##{input['id']}-error")).to be_present
    end
  end

  it "does not set tabindex on form controls" do
    expect(document.css("#registration-form [tabindex]")).to be_empty
  end
end
