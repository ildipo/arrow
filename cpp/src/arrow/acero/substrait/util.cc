// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements. See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership. The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

#include "arrow/acero/substrait/util.h"

#include <algorithm>
#include <optional>
#include <string_view>
#include <utility>

#include "arrow/buffer.h"
#include "arrow/compute/exec.h"
#include "arrow/compute/exec/exec_plan.h"
#include "arrow/compute/exec/options.h"
#include "arrow/compute/type_fwd.h"
#include "arrow/acero/substrait/extension_set.h"
#include "arrow/acero/substrait/serde.h"
#include "arrow/acero/substrait/type_fwd.h"
#include "arrow/status.h"
#include "arrow/type_fwd.h"
#include "arrow/util/async_generator.h"
#include "arrow/util/future.h"
#include "arrow/util/thread_pool.h"

namespace arrow {

namespace acero {

Result<std::shared_ptr<RecordBatchReader>> ExecuteSerializedPlan(
    const Buffer& substrait_buffer, const ExtensionIdRegistry* registry,
    compute::FunctionRegistry* func_registry, const ConversionOptions& conversion_options,
    bool use_threads, MemoryPool* memory_pool) {
  ARROW_ASSIGN_OR_RAISE(compute::Declaration plan,
                        DeserializePlan(substrait_buffer, registry,
                                        /*ext_set_out=*/nullptr, conversion_options));
  return compute::DeclarationToReader(std::move(plan), use_threads, memory_pool,
                                      func_registry);
}

Result<std::shared_ptr<Buffer>> SerializeJsonPlan(const std::string& substrait_json) {
  return acero::internal::SubstraitFromJSON("Plan", substrait_json);
}

std::shared_ptr<ExtensionIdRegistry> MakeExtensionIdRegistry() {
  return nested_extension_id_registry(default_extension_id_registry());
}

const std::string& default_extension_types_uri() {
  static std::string uri(acero::kArrowExtTypesUri);
  return uri;
}

}  // namespace acero

}  // namespace arrow
