# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

describe BrandableCSS do
  describe "all_brand_variable_values" do
    it "returns defaults if called without a brand config" do
      expect(BrandableCSS.all_brand_variable_values["ic-link-color"]).to eq "#2B7ABC"
    end

    it "includes image_url asset path for default images" do
      # un-memoize so it calls image_url double
      if BrandableCSS.instance_variable_get(:@variables_map_with_image_urls)
        BrandableCSS.remove_instance_variable(:@variables_map_with_image_urls)
      end
      url = "https://test.host/image.png"
      allow(ActionController::Base.helpers).to receive(:image_url).and_return(url)
      tile_wide = BrandableCSS.all_brand_variable_values["ic-brand-msapplication-tile-wide"]
      expect(tile_wide).to eq url
    end

    describe "when called with a brand config" do
      before :once do
        parent_config = BrandConfig.create(variables: { "ic-brand-primary" => "red" })

        subaccount_bc = BrandConfig.for(
          variables: { "ic-brand-global-nav-bgd" => "#123" },
          parent_md5: parent_config.md5,
          js_overrides: nil,
          css_overrides: nil,
          mobile_js_overrides: nil,
          mobile_css_overrides: nil
        )
        subaccount_bc.save!
        @brand_variables = BrandableCSS.all_brand_variable_values(subaccount_bc)
      end

      it "includes custom variables from brand config" do
        expect(@brand_variables["ic-brand-global-nav-bgd"]).to eq "#123"
      end

      it "includes custom variables from parent brand config" do
        expect(@brand_variables["ic-brand-primary"]).to eq "red"
      end

      it "handles named html colors when lightening/darkening" do
        {
          "ic-brand-primary" => "red",
          "ic-brand-primary-darkened-5" => "#F30000",
          "ic-brand-primary-darkened-10" => "#E60000",
          "ic-brand-primary-darkened-15" => "#D90000",
          "ic-brand-primary-lightened-5" => "#FF0C0C",
          "ic-brand-primary-lightened-10" => "#FF1919",
          "ic-brand-primary-lightened-15" => "#FF2626",
          "ic-brand-button--primary-bgd-darkened-5" => "#F30000",
          "ic-brand-button--primary-bgd-darkened-15" => "#D90000"
        }.each do |key, val|
          expect(@brand_variables[key]).to eq val
        end
      end

      it "includes default variables not found in brand config" do
        expect(@brand_variables["ic-link-color"]).to eq "#2B7ABC"
      end
    end
  end

  describe "all_brand_variable_values_as_js" do
    it "eports the default js to the right global variable" do
      expected_js = "CANVAS_ACTIVE_BRAND_VARIABLES = #{BrandableCSS.default("json")};"
      expect(BrandableCSS.default("js")).to eq expected_js
    end
  end

  describe "all_brand_variable_values_as_css" do
    it "defines the right default css values in the root scope" do
      expected_css = ":root {
        #{BrandableCSS.all_brand_variable_values(nil, true).map { |k, v| "--#{k}: #{v};" }.join("\n")}
      }"
      expect(BrandableCSS.default("css")).to eq expected_css
    end
  end

  describe "default_json" do
    it "includes default variables not found in brand config" do
      brand_variables = JSON.parse(BrandableCSS.default("json"))
      expect(brand_variables["ic-link-color"]).to eq "#2B7ABC"
    end

    it "has high contrast overrides for link and brand-primary" do
      brand_variables = JSON.parse(BrandableCSS.default("json", true))
      expect(brand_variables["ic-brand-primary"]).to eq "#0A5A9E"
      expect(brand_variables["ic-link-color"]).to eq "#2B7ABC"
    end
  end

  [true, false].each do |high_contrast|
    %w[js json css].each do |type|
      describe "save_default!(#{type})" do
        it "writes the default json representation to the default json file" do
          allow(Canvas::Cdn).to receive(:enabled?).and_return(false)
          file = StringIO.new
          allow(BrandableCSS).to receive(:default_brand_file).with(type, high_contrast).and_return(file)
          BrandableCSS.save_default!(type, high_contrast)
          expect(file.string).to eq BrandableCSS.default(type, high_contrast)
        end

        it "uploads json file to s3 if cdn is enabled" do
          allow(Canvas::Cdn).to receive_messages(
            enabled?: true,
            config: ActiveSupport::OrderedOptions.new.merge(region: "us-east-1",
                                                            aws_access_key_id: "id",
                                                            aws_secret_access_key: "secret",
                                                            bucket: "cdn")
          )

          file = StringIO.new
          allow(BrandableCSS).to receive(:default_brand_file).with(type, high_contrast).and_return(file)
          allow(File).to receive(:delete)
          expect(BrandableCSS.s3_uploader).to receive(:upload_file).with(BrandableCSS.public_default_path(type, high_contrast))
          BrandableCSS.save_default!(type, high_contrast)
        end

        it "deletes the local json file if cdn is enabled" do
          allow(Canvas::Cdn).to receive_messages(
            enabled?: true,
            config: ActiveSupport::OrderedOptions.new.merge(region: "us-east-1",
                                                            aws_access_key_id: "id",
                                                            aws_secret_access_key: "secret",
                                                            bucket: "cdn")
          )
          file = StringIO.new
          allow(BrandableCSS).to receive(:default_brand_file).with(type, high_contrast).and_return(file)
          expect(File).to receive(:delete).with(BrandableCSS.default_brand_file(type, high_contrast))
          expect(BrandableCSS.s3_uploader).to receive(:upload_file)
          BrandableCSS.save_default!(type, high_contrast)
        end
      end
    end
  end

  it "has a migration to generate BrandConfig records for the *latest* default variables" do
    migration_version = BrandableCSS.migration_version
    migration_name = BrandableCSS::MIGRATION_NAME.underscore

    predeploy_file = "db/migrate/#{migration_version}_#{migration_name}_predeploy.rb"
    postdeploy_file = "db/migrate/#{migration_version + 1}_#{migration_name}_postdeploy.rb"

    help = lambda do |oldfile:, newfile:|
      <<~TEXT
        If you have made changes to "app/stylesheets/brandable_variables.json"
        or any of the image files referenced in it, you must also rename the
        corresponding database migration file with a command similar to:

            mv #{oldfile} \\
               #{newfile}

        If you have no idea what this is about, reach out to the FOO team.
      TEXT
    end

    expect(Rails.root.join(predeploy_file)).to exist, help.call(
      oldfile: "db/migrate/*_#{migration_name}_predeploy.rb",
      newfile: predeploy_file
    )

    expect(Rails.root.join(postdeploy_file)).to exist, help.call(
      oldfile: "db/migrate/*_#{migration_name}_postdeploy.rb",
      newfile: postdeploy_file
    )
  end
end
