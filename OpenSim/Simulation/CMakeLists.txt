
set(SIMULATION_SUBDIRS 
        .
        Control
        Manager
        Model
        Wrap
        SimbodyEngine)

set(SOURCES)
set(INCLUDES)
foreach(dir ${SIMULATION_SUBDIRS})
    file(GLOB SOURCES_ONEDIR ${dir}/*.cpp)
    file(GLOB INCLUDES_ONEDIR ${dir}/*.h)
    list(APPEND SOURCES ${SOURCES_ONEDIR})
    list(APPEND INCLUDES ${INCLUDES_ONEDIR})
endforeach()

set(OpenSim_LIBRARIES_TO_USE)
if (WITH_RECORDER)
	list(APPEND OpenSim_LIBRARIES_TO_USE osimCommon_recorder)
else ()
	list(APPEND OpenSim_LIBRARIES_TO_USE osimCommon)
	list(APPEND OpenSim_LIBRARIES_TO_USE osimLepton)
endif()

OpenSimAddLibrary(
    KIT Simulation
    AUTHORS "Ajay_Seth-Michael_Sherman-Ayman_Habib"
	LINKLIBS ${Simbody_LIBRARIES_TO_USE} ${OpenSim_LIBRARIES_TO_USE}
    INCLUDES ${INCLUDES}
    SOURCES ${SOURCES}
    TESTDIRS SimbodyEngine Test
    INCLUDEDIRS ${SIMULATION_SUBDIRS}
    )
