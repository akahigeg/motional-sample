# -*- coding: utf-8 -*-

class AppDelegate < PM::Delegate
  # TODO: check orientation support
  def on_load(app, options)
    open GroupScreen.new(nav_bar: true)
  end
end

class GroupScreen < PM::TableScreen
  title "Asset Groups"

  def on_load
    set_nav_bar_button :right, title: "Add group", system_item: :add, action: :open_add_group
  end

  def on_appear
    @table_data = [{cells: []}]
    MotionAL.library.groups.each do |group|
      @table_data.first[:cells] << {
        title: group.name, 
        action: :tapped_group, 
        arguments: { group: group },
        accessory: { view: "(#{group.assets.count.to_s})".uilabel}
      }
      update_table_data
    end
  end

  def table_data
    @table_data ||= [{cells: []}]
  end

  def tapped_group(args)
    open AssetsScreen.new(group: args[:group])
  end

  def open_add_group
    screen = GroupAddScreen.new(nav_bar: true)
    screen.view.backgroundColor = UIColor.whiteColor
    open screen, modal: true, animated: true
  end
end

class GroupAddScreen < PM::Screen
  title "Add group"

  def on_load
    set_nav_bar_button :right, title: "Cancel", system_item: :cancel, action: :close_modal
    @name = FormHelper.create_text_field('group name', 50)

    @button = UIButton.rounded
    @button.frame = [[10, 110], [300, 50]]
    @button.setTitle("Add group", forState:UIControlStateNormal)

    @button.on(:touch_up_inside) do |e|
      MotionAL::Group.create(@name.text)
      close_modal
    end

    add @name
    add @button
  end

  def close_modal
    close
  end
end

class AssetsScreen < PM::TableScreen
  attr_accessor :group
  title "Assets"

  def on_load
    if @group.editable?
      set_nav_bar_button :right, title: "Add Asset", system_item: :add, action: :add_asset
    end
  end

  def on_appear
    reload_table
  end

  def add_asset
    BW::Device.camera.any.picture(media_types: [:image]) do |result|
      if !result.nil?
        MotionAL::Asset.find_by_url(result[:reference_url]) do |asset|
          # TODO: show alert when asset already exist in the group
          @group.assets << asset
        end
      end
    end
  end

  def table_data
    @table_data ||= [{cells: []}]
  end

  def reload_table
    @table_data = [{cells: []}]
    @group.assets.each do |asset|
      image = UIImage.alloc.initWithCGImage(asset.thumbnail)
      @table_data.first[:cells] << {
        title: asset.filename, 
        action: :tapped_asset, 
        arguments: { asset: asset },
        image: { image: image }
      }
      update_table_data
    end
  end

  def tapped_asset(args)
    open AssetViewScreen.new(asset: args[:asset])
  end
end

class AssetViewScreen < PM::Screen
  attr_accessor :asset
  title "Image"

  def on_load
    view.when_tapped do
      UIView.animateWithDuration(
        0.5, 
        animations: lambda { toggle_navigation_bar_alpha }
      )
    end
    set_nav_bar_button :right, title: "Info", action: :open_info
    show_image
  end

  def toggle_navigation_bar_alpha
    if self.navigation_controller.navigationBar.alpha == 0.0
      self.navigation_controller.navigationBar.alpha = 1.0
    else
      self.navigation_controller.navigationBar.alpha = 0.0
    end
  end

  def will_appear
    self.navigation_controller.navigationBar.barStyle = UIBarStyleBlack
    self.navigation_controller.navigationBar.translucent = true
  end

  def will_disappear
    self.navigation_controller.navigationBar.barStyle = UIBarStyleDefault
    self.navigation_controller.navigationBar.translucent = false
  end

  def will_rotate(orientation, duration)
    show_image
  end

  def show_image
    remove @image_view if @image_view

    @image = UIImage.alloc.initWithCGImage(@asset.full_screen_image)
    @image_view= UIImageView.alloc.initWithImage(@image.scale_to([Device.screen.width_for_orientation(Device.orientation), Device.screen.height_for_orientation(Device.orientation)]))

    add @image_view
  end

  def open_info
    open AssetInfoScreen.new(asset: @asset)
  end
end

class AssetInfoScreen < PM::TableScreen
  attr_accessor :asset
  title "Metadata"

  def on_load
    @table_data = []

    Dispatch::Queue.main.async do 
      @table_data << section_of_basic
      if @asset.asset_type == :photo
        @table_data << section_of_exif 
        @table_data << section_of_gps if @asset.metadata[KCGImagePropertyGPSDictionary]
      end
      update_table_data 
    end
  end

  def table_data
    @table_data ||= [{cells: []}]
  end

  def section_of_basic
    image = UIImage.alloc.initWithCGImage(@asset.thumbnail)

    {
      title: 'basic',
      cells: [
        {
          title: @asset.default_representation.filename,
          image: { image: image }
        }
      ]
    }
  end

  def section_of_exif
    {
      title: 'exif',
      cells: exif_cells
    }
  end

  def exif_cells
    exif = @asset.metadata[KCGImagePropertyExifDictionary]
    exif.map do |k,v|
      {title: "#{k}: #{v}"}
    end
  end

  def section_of_gps
    {
      title: 'gps',
      cells: gps_cells
    }
  end

  def gps_cells
    gps = @asset.metadata[KCGImagePropertyGPSDictionary]
    gps.map do |k,v|
      {title: "#{k}: #{v}"}
    end
  end

end

class FormHelper
  def self.create_text_field(placeholder, y)
    tf = UITextField.new
    tf.placeholder = placeholder
    tf.borderStyle = UITextBorderStyleRoundedRect
    tf.font = UIFont.systemFontOfSize(20)
    tf.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter
    tf.frame = [[10, y], [300, 50]]
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;

    tf
  end

  def self.create_password_field(placeholder, y)
    tf = create_text_field(placeholder, y)
    tf.secureTextEntry = true
    
    tf
  end
end
