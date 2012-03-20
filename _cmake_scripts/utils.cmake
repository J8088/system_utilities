macro( list_contains var value)
  set(${var})
  foreach (value2 ${ARGN})
    if ("${value}" STREQUAL "${value2}")
      set(${var} TRUE)
    endif ("${value}" STREQUAL "${value2}")
  endforeach (value2)
endmacro( list_contains )

function(test_variable_on_existance variable)
	if (NOT ${variable})
		MESSAGE( FATAL_ERROR "[ERROR: ] Variable ${variable} does not exist. Please set it by cmake -D${variable}=<value>." )
	endif()
endfunction(test_variable_on_existance)

function(test_variable_on_equal_to_one_of_the_list variable)
	list_contains(cmake_release_or_debug ${${variable}} ${ARGN} )
	if (NOT cmake_release_or_debug)
		create_string_from_list( str ${ARGN} )
		MESSAGE( FATAL_ERROR " [ERROR: ] Variable ${variable} (${${variable}}) does not fit to any allow value (${str}).")
	endif()
endfunction(test_variable_on_equal_to_one_of_the_list)

macro(create_string_from_list str)
	foreach(VALUE ${ARGN})
		if ("${VALUE}" STREQUAL "${ARGV1}")
			set(result "${VALUE}")
		else()
			set(result "${result} ${VALUE}")
		endif()
	endforeach(VALUE)
	set(${str} ${result})
endmacro(create_string_from_list) 

macro( modules )
	set( ${SOLUTION_NAME}_modules ${ARGN} )
	foreach (module ${${SOLUTION_NAME}_modules})
		set( ${module}_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/sources/${module} )
		set( ${module}_LIBRARIES ${module} )
		if ( ${VERBOSE} )
			message(STATUS "Setting variables for ${module}")
			message(STATUS "  - directory: ${${module}_INCLUDE_DIRS}")
			message(STATUS "  - library: ${${module}_LIBRARIES}" )
		endif( ${VERBOSE} )
	endforeach( module )
	add_subdirectory( sources )
	add_subdirectory( tests )
endmacro( modules )

macro( compile_modules )
	foreach (module ${${SOLUTION_NAME}_modules})
		set( module_name ${module} )
		add_subdirectory( ${module} )
	endforeach( module )
endmacro( compile_modules )

macro( compile_tests )
	foreach (module ${${SOLUTION_NAME}_modules} )
		if ( ${VERBOSE} )
			message(STATUS "Compiling tests for ${module} module.")
	    endif( ${VERBOSE} )
		set( module_name ${module} )
		set( tests_name ${module}_tests )
		add_subdirectory( ${tests_name} )
	endforeach( module )
endmacro( compile_tests )

macro( compile_project project_name source_pattern header_pattern build_type solution_folder )
	project( ${project_name} )
	if (${VERBOSE} )
		message(STATUS "* Creating project: ${project_name}(${build_type}) with '${solution_folder}' (${PROJECT_SOURCE_DIR}) from: ${source_pattern}, ${header_pattern}.")
	endif(${VERBOSE})

	add_definitions( -DSOURCE_DIR="${CMAKE_SOURCE_DIR}" )

	file(GLOB ${project_name}_SOURCES ${source_pattern})
	file(GLOB ${project_name}_HEADERS ${header_pattern})
	file(GLOB ${project_name}_SOURCE_LIST ${${project_name}_SOURCES} ${${project_name}_HEADERS}) 

	foreach( dependencie ${ARGN} )
		if(${VERBOSE})
			message(STATUS "   - Adding thread dependencie: '${${dependencie}_INCLUDE_DIRS}'")
		endif(${VERBOSE})
		include_directories( ${${dependencie}_INCLUDE_DIRS} )
	endforeach( dependencie )	

	if ("${build_type}" STREQUAL "STATIC")
		add_library(${project_name} STATIC ${${project_name}_SOURCE_LIST} )
		set( ${project_name}_INCLUDE_DIRS ${PROJECT_SOURCE_DIR} )
		if(${VERBOSE})
			message(STATUS "   - Creating static library: ${project_name}")
		endif(${VERBOSE})
	elseif( "${build_type}" STREQUAL "SHARED" )
		add_library(${project_name} SHARED ${${project_name}_SOURCE_LIST} )
		if(${VERBOSE})
			message(STATUS "   - Creating shared library: ${project_name}")
		endif(${VERBOSE})
	elseif( "${build_type}" STREQUAL "BINARY"  )
		add_executable( ${PROJECT_NAME} ${${PROJECT_NAME}_SOURCE_LIST})
		if(${VERBOSE})
			message(STATUS "   - Creating binary file: ${project_name}")
		endif(${VERBOSE})
	endif()

	if (NOT "${build_type}" STREQUAL "STATIC")
		foreach( dependencie ${ARGN} )
			target_link_libraries( ${project_name} ${${dependencie}_LIBRARIES} )	
			if(${VERBOSE})
				message(STATUS "   - Adding library dependencie: ${${dependencie}_LIBRARIES}")
			endif(${VERBOSE})
		endforeach( dependencie )	
	endif()

	set_property(TARGET ${project_name} PROPERTY FOLDER ${solution_folder})

endmacro( compile_project )

macro( register_test project_name tests_time_out tests_with_performance_time_out )
	add_test( ${project_name} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${project_name} )
	if (${RUN_PERFORMANCE_TESTS})
		set_tests_properties ( ${PROJECT_NAME} PROPERTIES TIMEOUT ${tests_with_performance_time_out} )
	else()
		set_tests_properties ( ${PROJECT_NAME} PROPERTIES TIMEOUT ${tests_time_out} )
	endif(${RUN_PERFORMANCE_TESTS})
endmacro( register_test )
