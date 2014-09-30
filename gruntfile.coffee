"use strict"

module.exports = (grunt) ->

  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt

  # Define the configuration for all the tasks
  grunt.initConfig

    # Project settings
    yeoman:
      # configurable paths
      app: require("./bower.json").appPath or "app"
      dist: "dist"


    # Watches files for changes and runs tasks based on the changed files
    watch:
      coffee:
        files: ["<%= yeoman.app %>/scripts/{,*/}*.{coffee,litcoffee,coffee.md}"]
        tasks: ["newer:coffee:dist","coffeelint"]

      compass:
        files: ["<%= yeoman.app %>/styles/{,*/}*.{scss,sass}"]
        tasks: [
          "compass:server"
          "autoprefixer"
        ]

      gruntfile:
        files: ["gruntfile.coffee"]

      indexfile:
        files: [
          "<%= yeoman.app %>/*.html"
          "<%= yeoman.app %>/views/{,*/}*.html"
        ]
        tasks: ["nginclude:server"]

      livereload:
        options:
          livereload: "<%= connect.options.livereload %>"

        files: [
          ".tmp/styles/{,*/}*.css"
          ".tmp/*.html"
          ".tmp/scripts/{,*/}*.js"
          "<%= yeoman.app %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}"
        ]

    # The actual grunt server settings
    connect:
      options:
        port: 8000
        hostname: "0.0.0.0"
        livereload: 35720

      livereload:
        options:
          open: true
          base: [
            ".tmp"
            "<%= yeoman.app %>"
          ]

      dist:
        options:
          base: "<%= yeoman.dist %>"

    # Empties folders to start fresh
    clean:
      dist:
        files: [
          dot: true
          src: [
            ".tmp"
            "<%= yeoman.dist %>/*"
            "!<%= yeoman.dist %>/.git*"
          ]
        ]

      server: ".tmp"


    # Add vendor prefixed styles
    autoprefixer:
      options:
        browsers: ["last 1 version"]

      dist:
        files: [
          expand: true
          cwd: ".tmp/styles/"
          src: "{,*/}*.css"
          dest: ".tmp/styles/"
        ]

    # Automatically inject Bower components into the app
    "bower-install":
      app:
        html: "<%= yeoman.app %>/index.html"
        ignorePath: "<%= yeoman.app %>/"
        exclude: ["bower_components/sass-bootstrap/dist/css/bootstrap.css"]

    # Compiles CoffeeScript to JavaScript
    coffee:
      options:
        sourceMap: true
        sourceRoot: ""

      dist:
        files: [
          expand: true
          cwd: "<%= yeoman.app %>/scripts"
          src: "{,*/}*.coffee"
          dest: ".tmp/scripts"
          ext: ".js"
        ]
    coffeelint:
      options:
        configFile: "coffeelint.json"
      all:
        expand: true
        cwd: "<%= yeoman.app %>/scripts"
        src: "**/*.coffee"

    # Compiles Sass to CSS and generates necessary files if requested
    compass:
      options:
        sassDir: "<%= yeoman.app %>/styles"
        cssDir: ".tmp/styles"
        generatedImagesDir: ".tmp/images/generated"
        imagesDir: "<%= yeoman.app %>/images"
        javascriptsDir: "<%= yeoman.app %>/scripts"
        fontsDir: "<%= yeoman.app %>/styles/fonts"
        importPath: "<%= yeoman.app %>/bower_components"
        httpImagesPath: "/images"
        httpGeneratedImagesPath: "/images/generated"
        httpFontsPath: "/styles/fonts"
        relativeAssets: false
        assetCacheBuster: false
        raw: "Sass::Script::Number.precision = 10\n"

      dist:
        options:
          generatedImagesDir: "<%= yeoman.dist %>/images/generated"

      server:
        options:
          debugInfo: true

    # Reads HTML for usemin blocks to enable smart builds that automatically
    # concat, minify and revision files. Creates configurations in memory so
    # additional tasks can operate on them
    useminPrepare:
      html: "<%= yeoman.app %>/index.html"
      options:
        dest: "<%= yeoman.dist %>"

    # Performs rewrites based on rev and the useminPrepare configuration
    usemin:
      html: ["<%= yeoman.dist %>/{,*/}*.html"]
      css: ["<%= yeoman.dist %>/styles/{,*/}*.css"]
      options:
        assetsDirs: ["<%= yeoman.dist %>"]

    htmlmin:
      dist:
        options:
          collapseWhitespace: true
          collapseBooleanAttributes: true
          removeCommentsFromCDATA: true
          removeOptionalTags: true

        files: [
          expand: true
          cwd: "<%= yeoman.dist %>"
          src: [
            "*.html"
            "views/{,*/}*.html"
          ]
          dest: "<%= yeoman.dist %>"
        ]

    nginclude:
      options:
        assetsDirs: ["<%= yeoman.app %>"]

      server:
        # Target-specific file lists and/or options go here.
        files: [
          expand: true
          cwd: "<%= yeoman.app %>"
          src: "index.html"
          dest: ".tmp/"
        ]

      dist:
        # Target-specific file lists and/or options go here.
        files: [
          expand: true
          cwd: "<%= yeoman.dist %>"
          src: [
            "*.html"
            "views/{,*/}*.html"
          ]
          dest: "<%= yeoman.dist %>"
        ]

    # Copies remaining files to places other tasks can use
    copy:
      dist:
        files: [
          {
            expand: true
            dot: true
            cwd: "<%= yeoman.app %>"
            dest: "<%= yeoman.dist %>"
            src: [
              "*.{ico,png,txt}"
              ".htaccess"
              "*.html"
              "images/{,*/}*.{webp}"
              "fonts/*"
            ]
          }
          {
            expand: true
            cwd: "<%= yeoman.app %>/images"
            dest: "<%= yeoman.dist %>/images"
            src: ["*"]
          }
        ]

      styles:
        expand: true
        cwd: "<%= yeoman.app %>/styles"
        dest: ".tmp/styles/"
        src: "{,*/}*.css"

    # Run some tasks in parallel to speed up the build process
    concurrent:
      server: [
        "coffee:dist"
        "compass:server"
        "nginclude:server"
      ]
      dist: [
        "coffeelint"
        "coffee"
        "compass:dist"
      ]
    concat:
        extra_html:
            src: [
                "dist/index.html"
                ".extra_html"
            ]
            dest: "dist/index.html"

  grunt.registerTask "serve", (target) ->
    if target is "dist"
      return grunt.task.run([
        "build"
        "connect:dist:keepalive"
      ])
    grunt.task.run [
      "clean:server"
      "bower-install"
      "concurrent:server"
      "autoprefixer"
      "connect:livereload"
      "watch"
    ]

  grunt.registerTask "build", [
    "clean:dist"
    "bower-install"
    "useminPrepare"
    "concurrent:dist"
    "autoprefixer"
    "concat:generated"
    "copy:dist"
    "cssmin"
    "uglify"
    "nginclude"
    "usemin"
    "concat:extra_html"
    "htmlmin"
  ]

  grunt.registerTask "default", [
    "build"
  ]
