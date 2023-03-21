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

# distutils: language = c++

from pyarrow.includes.common cimport *
from pyarrow.includes.libarrow cimport *


cdef extern from "arrow/acero/groupby.h" namespace \
        "arrow::compute" nogil:
    cdef cppclass CAggregate "arrow::compute::Aggregate":
        c_string function
        shared_ptr[CFunctionOptions] options
        vector[CFieldRef] target
        c_string name

    CResult[shared_ptr[CTable]] CTableGroupBy "arrow::compute::TableGroupBy"(
        shared_ptr[CTable] table,
        vector[CAggregate] aggregates,
        vector[CFieldRef] keys)


cdef extern from "arrow/acero/options.h" namespace "arrow::compute" nogil:
    cdef enum CJoinType "arrow::compute::JoinType":
        CJoinType_LEFT_SEMI "arrow::compute::JoinType::LEFT_SEMI"
        CJoinType_RIGHT_SEMI "arrow::compute::JoinType::RIGHT_SEMI"
        CJoinType_LEFT_ANTI "arrow::compute::JoinType::LEFT_ANTI"
        CJoinType_RIGHT_ANTI "arrow::compute::JoinType::RIGHT_ANTI"
        CJoinType_INNER "arrow::compute::JoinType::INNER"
        CJoinType_LEFT_OUTER "arrow::compute::JoinType::LEFT_OUTER"
        CJoinType_RIGHT_OUTER "arrow::compute::JoinType::RIGHT_OUTER"
        CJoinType_FULL_OUTER "arrow::compute::JoinType::FULL_OUTER"

    cdef cppclass CAsyncExecBatchGenerator "arrow::compute::AsyncExecBatchGenerator":
        pass

    cdef cppclass CExecNodeOptions "arrow::compute::ExecNodeOptions":
        pass

    cdef cppclass CSourceNodeOptions "arrow::compute::SourceNodeOptions"(CExecNodeOptions):
        pass

    cdef cppclass CTableSourceNodeOptions "arrow::compute::TableSourceNodeOptions"(CExecNodeOptions):
        CTableSourceNodeOptions(shared_ptr[CTable] table)
        CTableSourceNodeOptions(shared_ptr[CTable] table, int64_t max_batch_size)

    cdef cppclass CSinkNodeOptions "arrow::compute::SinkNodeOptions"(CExecNodeOptions):
        pass

    cdef cppclass CFilterNodeOptions "arrow::compute::FilterNodeOptions"(CExecNodeOptions):
        CFilterNodeOptions(CExpression)

    cdef cppclass CProjectNodeOptions "arrow::compute::ProjectNodeOptions"(CExecNodeOptions):
        CProjectNodeOptions(vector[CExpression] expressions)
        CProjectNodeOptions(vector[CExpression] expressions,
                            vector[c_string] names)

    cdef cppclass CAggregateNodeOptions "arrow::compute::AggregateNodeOptions"(CExecNodeOptions):
        CAggregateNodeOptions(vector[CAggregate] aggregates, vector[CFieldRef] names)

    cdef cppclass COrderBySinkNodeOptions "arrow::compute::OrderBySinkNodeOptions"(CExecNodeOptions):
        COrderBySinkNodeOptions(vector[CSortOptions] options,
                                CAsyncExecBatchGenerator generator)

    cdef cppclass CHashJoinNodeOptions "arrow::compute::HashJoinNodeOptions"(CExecNodeOptions):
        CHashJoinNodeOptions(CJoinType, vector[CFieldRef] in_left_keys,
                             vector[CFieldRef] in_right_keys)
        CHashJoinNodeOptions(CJoinType, vector[CFieldRef] in_left_keys,
                             vector[CFieldRef] in_right_keys,
                             CExpression filter,
                             c_string output_suffix_for_left,
                             c_string output_suffix_for_right)
        CHashJoinNodeOptions(CJoinType join_type,
                             vector[CFieldRef] left_keys,
                             vector[CFieldRef] right_keys,
                             vector[CFieldRef] left_output,
                             vector[CFieldRef] right_output,
                             CExpression filter,
                             c_string output_suffix_for_left,
                             c_string output_suffix_for_right)


cdef extern from "arrow/acero/exec_plan.h" namespace "arrow::compute" nogil:
    cdef cppclass CDeclaration "arrow::compute::Declaration":
        cppclass Input:
            Input(CExecNode*)
            Input(CDeclaration)

        c_string label
        vector[Input] inputs

        CDeclaration()
        CDeclaration(c_string factory_name, CExecNodeOptions options)
        CDeclaration(c_string factory_name, vector[Input] inputs, shared_ptr[CExecNodeOptions] options)

        @staticmethod
        CDeclaration Sequence(vector[CDeclaration] decls)

        CResult[CExecNode*] AddToPlan(CExecPlan* plan) const

    cdef cppclass CExecPlan "arrow::compute::ExecPlan":
        @staticmethod
        CResult[shared_ptr[CExecPlan]] Make(CExecContext* exec_context)

        void StartProducing()
        CStatus Validate()
        CStatus StopProducing()

        CFuture_Void finished()

        vector[CExecNode*] sinks() const
        vector[CExecNode*] sources() const

    cdef cppclass CExecNode "arrow::compute::ExecNode":
        const vector[CExecNode*]& inputs() const
        const shared_ptr[CSchema]& output_schema() const

    cdef cppclass CExecBatch "arrow::compute::ExecBatch":
        vector[CDatum] values
        int64_t length

    shared_ptr[CRecordBatchReader] MakeGeneratorReader(
        shared_ptr[CSchema] schema,
        CAsyncExecBatchGenerator gen,
        CMemoryPool* memory_pool
    )
    CResult[CExecNode*] MakeExecNode(c_string factory_name, CExecPlan* plan,
                                     vector[CExecNode*] inputs,
                                     const CExecNodeOptions& options)

    CResult[shared_ptr[CTable]] DeclarationToTable(
        CDeclaration declaration, c_bool use_threads
    )
    CResult[shared_ptr[CTable]] DeclarationToTable(
        CDeclaration declaration, c_bool use_threads,
        CMemoryPool* memory_pool, CFunctionRegistry* function_registry
    )
    CResult[unique_ptr[CRecordBatchReader]] DeclarationToReader(
        CDeclaration declaration, c_bool use_threads
    )

    CResult[c_string] DeclarationToString(const CDeclaration& declaration)
