# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

add_custom_target(arrow_acero)

arrow_install_all_headers("arrow/acero")

# pkg-config support
#arrow_add_pkg_config("arrow-acero")

set(ARROW_ACERO_SRCS
      groupby.cc
      accumulation_queue.cc
      aggregate_node.cc
      asof_join_node.cc
      bloom_filter.cc
      exec_plan.cc
      fetch_node.cc
      filter_node.cc
      hash_join.cc
      hash_join_dict.cc
      hash_join_node.cc
      map_node.cc
      options.cc
      order_by_impl.cc
      partition_util.cc
      pivot_longer_node.cc
      project_node.cc
      query_context.cc
      sink_node.cc
      source_node.cc
      swiss_join.cc
      task_util.cc
      tpch_node.cc
      union_node.cc
      util.cc)

append_avx2_src(bloom_filter_avx2.cc)
append_avx2_src(swiss_join_avx2.cc)
append_avx2_src(util_avx2.cc)

add_arrow_lib(arrow_acero
              CMAKE_PACKAGE_NAME
              ArrowAcero
              PKG_CONFIG_NAME
              arrow-acero
              OUTPUTS
              ARROW_ACERO_LIBRARIES
              SOURCES
              ${ARROW_ACERO_SRCS}
              PRECOMPILED_HEADERS
              "$<$<COMPILE_LANGUAGE:CXX>:arrow/acero/pch.h>"
              SHARED_LINK_FLAGS
              ${ARROW_VERSION_SCRIPT_FLAGS} # Defined in cpp/arrow/CMakeLists.txt
              SHARED_LINK_LIBS
              SHARED_INSTALL_INTERFACE_LIBS
              Arrow::arrow_shared
              STATIC_LINK_LIBS
              STATIC_INSTALL_INTERFACE_LIBS
              Arrow::arrow_static)

set(ARROW_ACERO_TEST_LINK_LIBS ${ARROW_LINK_lIBS} ${ARROW_TEST_LINK_LIBS})
if(ARROW_TEST_LINKAGE STREQUAL "static")
  list(APPEND ARROW_ACERO_TEST_LINK_LIBS arrow_acero_static)
else()
  list(APPEND ARROW_ACERO_TEST_LINK_LIBS arrow_acero_shared)
endif()

function(ADD_ARROW_ACERO_TEST REL_TEST_NAME)
  set(options REQUIRE_ALL_KERNELS)
  set(one_value_args PREFIX)
  set(multi_value_args LABELS)
  cmake_parse_arguments(ARG
          "${options}"
          "${one_value_args}"
          "${multi_value_args}"
          ${ARGN})

  if(ARG_REQUIRE_ALL_KERNELS AND (NOT ARROW_COMPUTE))
    return()
  endif()

  if(ARG_PREFIX)
    set(PREFIX ${ARG_PREFIX})
  else()
    set(PREFIX "arrow-acero")
  endif()

  if(ARG_LABELS)
    set(LABELS ${ARG_LABELS})
  else()
    set(LABELS "arrow_acero")
  endif()

  add_arrow_test(${REL_TEST_NAME}
          EXTRA_LINK_LIBS
          ${ARROW_ACERO_TEST_LINK_LIBS}
          PREFIX
          ${PREFIX}
          SOURCES
          test_util_internal.cc
          LABELS
          ${LABELS}
          ${ARG_UNPARSED_ARGUMENTS})
endfunction()

add_arrow_acero_test(subtree_test
        REQUIRE_ALL_KERNELS
        PREFIX
        "arrow-acero"
        SOURCES
        subtree_test.cc)

add_arrow_acero_test(plan_test
        REQUIRE_ALL_KERNELS
        PREFIX
        "arrow-acero"
        SOURCES
        plan_test.cc
        test_nodes_test.cc
        test_nodes.cc)
add_arrow_acero_test(fetch_node_test
        REQUIRE_ALL_KERNELS
        PREFIX
        "arrow-acero"
        SOURCES
        fetch_node_test.cc
        test_nodes.cc)
add_arrow_acero_test(hash_join_node_test
        REQUIRE_ALL_KERNELS
        PREFIX
        "arrow-acero"
        SOURCES
        hash_join_node_test.cc
        bloom_filter_test.cc)
add_arrow_acero_test(pivot_longer_node_test
        PREFIX
        "arrow-acero"
        SOURCES
        pivot_longer_node_test.cc
        test_nodes.cc)
add_arrow_acero_test(asof_join_node_test
        REQUIRE_ALL_KERNELS
        PREFIX
        "arrow-acero"
        SOURCES
        asof_join_node_test.cc
        test_nodes.cc)
add_arrow_acero_test(tpch_node_test
        PREFIX 
        "arrow-acero")
add_arrow_acero_test(union_node_test
        PREFIX
        "arrow-acero")
add_arrow_acero_test(groupby_test
        REQUIRE_ALL_KERNELS
        PREFIX "arrow-acero")
add_arrow_acero_test(util_test
        PREFIX
        "arrow-acero"
        SOURCES
        util_test.cc
        task_util_test.cc)

add_arrow_benchmark(expression_benchmark
        PREFIX
        "arrow-compute")

add_arrow_benchmark(filter_benchmark
        PREFIX
        "arrow-acero"
        SOURCES
        benchmark_util.cc
        filter_benchmark.cc)

add_arrow_benchmark(project_benchmark
        PREFIX
        "arrow-acero"
        SOURCES
        benchmark_util.cc
        project_benchmark.cc)

add_arrow_benchmark(asof_join_benchmark
        PREFIX
        "arrow-acero")

add_arrow_benchmark(tpch_benchmark
        PREFIX
        "arrow-acero")

if(ARROW_BUILD_OPENMP_BENCHMARKS)
  find_package(OpenMP REQUIRED)
  add_arrow_benchmark(hash_join_benchmark
          PREFIX
          "arrow-acero"
          EXTRA_LINK_LIBS
          OpenMP::OpenMP_CXX)
  if(MSVC)
    target_compile_options(arrow-compute-hash-join-benchmark
            PRIVATE "-openmp:experimental -openmp:llvm")
  endif()
endif()
