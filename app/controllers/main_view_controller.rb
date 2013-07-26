# -*- encoding : utf-8 -*-

class MainViewController < UIViewController
  def create_button(title, frame, &block)
    button = UIButton.rounded_rect.tap do |b|
      b.setTitle(title, forState:UIControlStateNormal)
      b.accessibilityLabel = title
      b.frame = frame
      b.on(:touch) do |event|
        block.call(event)
      end
    end
  end

  def viewDidLoad
    super
    @library = MotionAL.library
    @test_group_name = 'MotionAL'
    # @test_group = MotionAL::Group.find_by_name(@test_group_name)

    @prepare_button = create_button('Prepare', [[20, 50], [280, 42]]) do |event|
      App.alert(@library.groups.map{|g|g.name}.join(':'))
      App.alert(@library.photo_library.name)

#      @library.groups.create('hogetta-')
#      @library.groups.create(@test_group_name) do |group, error|
#        if group.nil? # maybe group already exist
#          @test_group = MotionAL::Group.find_by_name(@test_group_name)
#          p @test_group.url
#          @found_group = MotionAL::Group.find_by_url(@test_group.url)
#          p @found_group.name
#          p error if error
#        else
#          @test_group = group
#        end
#        p "before: #{@library.groups.count}"
#        @library.groups.reload
#        p "after: #{@library.groups.count}"
#
#        @saved_photos = @library.saved_photos
#        @test_group.name
#
#        @test_asset = @saved_photos.assets.first
#        @test_group.assets << @test_asset
#        p @test_asset.metadata
#      end
#
#      p "without block"
#      @library.groups.all.each do |g|
#        p g.name #if !g.nil?
#      end
#
#      p "with block"
#      @library.groups.all do |g, e|
#        p g.name #if !g.nil?
#      end
    end
    view << @prepare_button

    @dummy_button = create_button('Dummy', [[20, 150], [280, 42]]) do |event|
      group = MotionAL::Group.create("hagehigehige")
      p group.name
    end
    view << @dummy_button

    self.view.backgroundColor = UIColor.whiteColor

    # create asset from image data and videopath
    # update asset

    # add asset to group
    @add_asset_button = UIButton.rounded_rect.tap do |b|
      b.setTitle('Add Asset to Group', forState:UIControlStateNormal)
      b.accessibilityLabel = "Add Asset"
      b.frame = [[20, 300], [280, 42]]
      b.on(:touch) do |event|
        BW::Device.camera.any.picture(media_types: [:image]) do |result|
          # image_view = build_image_view(result[:original_image])
          # self.view.addSubview(image_view)
          result.each do |k,v|
            NSLog "#{k}: #{v}"
          end

        #cg_image_url = NSBundle.mainBundle.URLForResource("sample", withExtension: "jpg")
        #cg_image = CGImageSourceCreateWithURL(cg_image_url, nil);
        #meta = CGImageSourceCopyPropertiesAtIndex(cg_image, 0, nil)

          cg_image = result[:original_image].CGImage
          meta = result[:media_metadata]
   
          asset = @test_group.assets.create(cg_image, meta)
          hoge_group = MotionAL::Group.find_by_name('hogetta-')
          hoge_group.assets << asset

          @test_group.assets.create(cg_image, meta) do |asset, error|
            if error.nil?
              ret = @test_group.assets << asset
              p "add asset result: #{ret}"
   
              p "size: #{asset.representations.size}"
              asset.representations.each do |rep|
                p "metadata: "
                p rep.metadata
              end
            else
              p error
            end
            p "finished."
          end
        end
      end
    end

    view << @add_asset_button
  end

end

__END__

  def viewDidLoad
    super
    margin = 20

    p @prepare.title

    @library = MotionAL.new

    self.view.backgroundColor = UIColor.whiteColor

    # add group
    @add_group_button = UIButton.rounded_rect.tap do |b|
      b.setTitle('Add Group1', forState:UIControlStateNormal)
      b.accessibilityLabel = "Add Group"
      b.frame = [[margin, 100], [view.frame.size.width - margin * 2, 42]]
      b.on(:touch) do |event|
        @was_tapped = true
        @added_group_name = "g_#{Time.now.to_i.to_s}"
        @library.groups.create(@added_group_name) do |group, error|
          @library.groups << group if error.nil? && !group.nil?
          p error.message if error
          p @library.groups.size
        end
      end
    end

    # create asset from image data and videopath
    # update asset

    # add asset to group
    @add_asset_button = UIButton.rounded_rect.tap do |b|
      b.setTitle('Add Asset to Group', forState:UIControlStateNormal)
      b.accessibilityLabel = "Add Asset"
      b.frame = [[margin, 300], [view.frame.size.width - margin * 2, 42]]
      b.on(:touch) do |event|
        BW::Device.camera.any.picture(media_types: [:image]) do |result|
          # image_view = build_image_view(result[:original_image])
          # self.view.addSubview(image_view)
          result.each do |k,v|
            NSLog "#{k}: #{v}"
          end

        #cg_image_url = NSBundle.mainBundle.URLForResource("sample", withExtension: "jpg")
        #cg_image = CGImageSourceCreateWithURL(cg_image_url, nil);
        #meta = CGImageSourceCopyPropertiesAtIndex(cg_image, 0, nil)

          cg_image = result[:original_image].CGImage
          meta = result[:media_metadata]
   
          @library.groups.last.assets.create(cg_image, meta) do |asset, error|
            if error.nil?
              ret = @library.groups.last.assets << asset
              p "add asset result: #{ret}"
   
              p "size: #{asset.representations.size}"
              asset.representations.each do |rep|
                p "metadata: "
                p rep.metadata
              end
            else
              p error
            end
            p "finished."
          end
        end
      end
    end

    view << @add_group_button
    view << @add_asset_button
  end

      BW::Device.camera.send(camera_method).picture(media_types: [:image]) do |result|
        image_view = build_image_view(result[:original_image])
        # self.view.addSubview(image_view)
        result.each do |k,v|
          NSLog "#{k}: #{v}"
        end

        if camera_method != :any
          library = ALAssetsLibrary.alloc.init
          library.writeImageToSavedPhotosAlbum(
            result[:original_image].CGImage,
            orientation: ALAssetOrientationUp,
            completionBlock: lambda {|asset_url, error|
              App.alert("saved!")

              MotionExif::Asset.read(asset_url) do |exif|
                p exif.keys
                cells = []
                exif.keys.each do |k|
                  cells << {:title => k.to_s}
                end
                @table_data = [
                  { title: "EXIF", cells: cells }
                ]
                update_table_data
              end
            }
          )

          #AssetsLibrary::ImageRef.new(result[:original_image].CGImage).save(result[:media_metadata]) do |asset_url|

          #end
        else
          result.each do |k,v|
            p "#{k}: #{v}"
          end

          MotionExif::Asset.read(result[:reference_url]) do |exif|
            p exif.keys
            cells = []
            exif.keys.each do |k|
              cells << {:title => k.to_s}
            end
            @table_data = [
              { title: "EXIF", cells: cells }
            ]
            update_table_data
          end
        end

#        MotionExif::Asset.read(result[:reference_url]) do |exif|
#          p exif.keys
#          cells = []
#          exif.keys.each do |k|
#            cells << {:title => k.to_s}
#          end
#          @table_data = [
#            { title: "EXIF", cells: cells }
#          ]
#          update_table_data
#        end

        self.buttons.each { |button| self.view.bringSubviewToFront(button) }
      end
