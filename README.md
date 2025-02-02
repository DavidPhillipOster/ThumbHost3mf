# ThumbHost3mf
A macOS app that hosts a thumbnail provider that makes the Finder displays the thumbnails built in to some .gcode, .bgcode, and .3mf files.

I got tired of my gcode and 3mf files looking like ![](images/before.png) 

 when they could look like this: ![](images/thumbs.png)

## IMPORTANT: 

* macOS requires that apps that host Quicklook plugins, like ThumbHost3MF, MUST be in `/Applications` or one of its subdirectories for the Quicklook plugin to function correctly! Note this is the actual `/Application` directory, and not an Application directory inside your home directory.

## To Install:

* Download and put the ThumbHost3MF app in `/Applications` or a subdirectory of `/Applications`. Run the ThumbHost3MF app. You only need to run it once to register the Quicklook plugin it contains.
If you don't want to compile the app yourself, grab the compiled code from [Releases](https://github.com/DavidPhillipOster/ThumbHost3MF/releases/tag/1.6)

* Use ThumbHost3MF's **File > Open** menu item and point at a directory containing .gcode or .3mf files: that will kick the Finder into noticing the embedded thumbnail presenter. (You can open a .gcode or .3mf file at this point to prove that ThumbHost3MF can see the embedded thumbnail image in it.)

* To compile it yourself, use your team and domain name. I uploaded this as com.example, but in the release I signed it with my team and domain name.

To get previews in your GCode files, in PrusaSlicer, in Printer Settings, set the thumbnail size to something reasonable. (I use 128x128, but you may need other sizes.)

   ![](images/128x128.png)

This will cause PrusaSlicer to append a base64-encoded 128x128 .png image of the gcode to near the start of the gcode file.

* You may need to use ThumbHost3MF's **Open** command to let the Finder know that it has a thumbnail provider.

* You may find that the Finder has made ThumbHost3MF the default app for .3mf and .gcode files. If that happens, in Finder, do a Get Info any .3mf and .gcode file and set the default app to what you wish.

* Not all .3mf files have an included thumbnail. I'm using those that, when unzipped, have a Metadata/thumbnail.png or .jpg. Most .3mf files created in 2021 or later do.

* In the `Original Prusa Drivers 2.5.0` distribution, in the `Sample Objects`  subdirectory, the `MK3_MK3S_MK3S+/3MF` folder has .3mf files with embedded thumbnails, but the `MINI_MINI+/3MF` files do not. 

If you open the `MINI_MINI+/3MF` files and **Save** them, PrusaSlicer adds the thumbnails.

I'm posting this to get early feedback. In an ideal world, the thumbnail provider would be inside the PrusaSlicer app and  this app would not be necessary. If this app does not break the world, I'll work on submitting a pull request on PrusaSlicer.

## To Build in Xcode

In the project build setting, the `DEVELOPER_PREFIX` is set to `com.example` - change it to your actual prefix.

Currently, the project on Github has no `DEVELOPMENT_TEAM` you should set this in the `Signing and Capabilities` panel of the project's targets.

You may also need to set a current scheme.

## Other

1/15/2024 is the day I learned that https://github.com/jkavalik/GcodeThumbnailExtension makes .gcode icons visible on Microsoft Windows. I haven't tried it so I can't comment on quality.

## Versions

* Version original 1.0 only handle gcode files, and only png and jpg thumbnails.

* Version 1.2 handles those and also bgcode files, and qoi thumbnails.

* Version 1.3 sets the minimum compatible version of macOS to OS X 10.15, Catalina from 2019, but still works through macOS Sonoma, 14.2.1, 2023. OS X 10.15 is the earliest because the embedded QuickLook plugin inherits from a class in the QuicklookThumbnailing framework that was introduced then.

* Version 1.4 extends this to also handle thumbnails inside Bambu Studio or Orca Slicer

* Version 1.5 adds a settings dialog box to the app to allow the user to control whether the icons are labeled with the filetype. Labeling is on by default.

* Version 1.6 corrects the Open items in the File menu, which were accidentally disabled as I went from a Document based app. The plugin was not affected.

* Version 1.7 Thanks to [yungsnuzzy](https://github.com/yungsnuzzy) who showed me a .3mf compressed with a new version of the [ZIP file format](https://en.wikipedia.org/wiki/ZIP_\(file_format\)), probably [ZIP 64](https://en.wikipedia.org/wiki/ZIP_\(file_format\)#ZIP64). I've updated ThumbMF3's minizip to use https://zlib.net/ zlib-1.3.1/contrib/minizip

## License

Apache 2 [License](LICENSE)

## Acknowledgements

minizip from https://zlib.net/

