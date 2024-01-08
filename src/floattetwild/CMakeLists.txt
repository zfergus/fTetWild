set(SOURCES
	AABBWrapper.h
	AABBWrapper.cpp

	auto_table.hpp
	auto_table.cpp

	CSGTreeParser.hpp
	CSGTreeParser.cpp

	LocalOperations.h
	LocalOperations.cpp
	EdgeSplitting.h
	EdgeSplitting.cpp
	EdgeCollapsing.h
	EdgeCollapsing.cpp
	EdgeSwapping.h
	EdgeSwapping.cpp
	VertexSmoothing.h
	VertexSmoothing.cpp

	MeshImprovement.h
	MeshImprovement.cpp


	FloatTetwild.h
	FloatTetwild.cpp

	FloatTetDelaunay.h
	FloatTetDelaunay.cpp
	TriangleInsertion.cpp
	TriangleInsertion.h

	CutMesh.cpp
	CutMesh.h

	intersections.h
	intersections.cpp

	Simplification.h
	Simplification.cpp

	Mesh.cpp
	Mesh.hpp

	MeshIO.hpp
	MeshIO.cpp

	Logger.hpp
	Logger.cpp

	Parameters.h

	Types.hpp

	Statistics.h
)

source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" PREFIX "Source Files" FILES ${SOURCES})
target_sources(${PROJECT_NAME} PRIVATE ${SOURCES})

################################################################################
# Subfolders
################################################################################

add_subdirectory(external)
