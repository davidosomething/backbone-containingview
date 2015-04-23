module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      src:
        options:
          bare: true
        files: [
          expand: true
          cwd: 'src'
          src: ['*.coffee']
          dest: 'dist'
          ext: '.js'
        ]


  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.registerTask 'default', [
    'coffee'
  ]
