//
// Created by qiuwenchen on 2023/11/28.
//

/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#pragma once

#include "Compression.hpp"
#include "DecorativeHandle.hpp"

namespace WCDB {

class CompressingHandleDecorator : public HandleDecorator, public Compression::Binder {
private:
    using Super = HandleDecorator;
#pragma mark - Initialize
public:
    CompressingHandleDecorator(Compression &compression);
    ~CompressingHandleDecorator() override;

    void decorate(Decorative *handle) override final;

#pragma mark - InfoInitializer
    InnerHandle *getCurrentHandle() const override final;
    bool commitTransaction() override final;
    void rollbackTransaction() override final;

#pragma mark - Statement
public:
    DecorativeHandleStatement *
    getStatement(const UnsafeStringView &skipDecorator) override final;
};

} // namespace WCDB
