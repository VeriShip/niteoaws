module.exports = (grunt) =>

	grunt.initConfig
		createDirectories:
			dir: ['bin']
		cleanUpDirectories:
			dir: ['bin']
		coffee:
			compile:
				expand: true,
				flatten: false,
				dest: 'bin/lib',
				src: ['**/*.coffee', '!**/gruntfile*'],
				ext: '.js',
				cwd: 'lib'
			compileTests:
				expand: true,
				flatten: false,
				dest: 'bin/tests',
				src: ['**/*.coffee', '!**/gruntfile*'],
				ext: '.js',
				cwd: 'tests'
		mochaTest:
			test:
				options:
					reporter: 'spec'
				src: ['bin/tests/**/*.js']


	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-mocha-test');

	grunt.registerTask('default', [ 'build' ]);
	grunt.registerTask('build', [ 'createDirectories', 'coffee:compile', 'coffee:compileTests', 'mochaTest:test' ]);
	grunt.registerTask('clean', [ 'cleanUpDirectories' ]);
	grunt.registerTask('rebuild', [ 'clean', 'build' ]);

	grunt.registerMultiTask 'createDirectories', ->
		for dir in this.data
			if not grunt.file.exists dir
				grunt.file.mkdir dir

	grunt.registerMultiTask 'cleanUpDirectories', ->
		for dir in this.data
			if grunt.file.exists dir
				grunt.file.recurse dir, (abspath) ->
					grunt.file.delete abspath
				grunt.file.delete dir, { force: true }
