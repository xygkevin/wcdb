// Created by qiuwenchen on 2023/6/12.
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

package com.tencent.wcdbtest.winq;

import org.junit.Test;
import static com.tencent.wcdbtest.base.WinqTool.winqEqual;

import com.tencent.wcdb.winq.StatementReindex;

public class StatementReindexTest {
    @Test
    public void test() {
        winqEqual(new StatementReindex().reindexTable("testTable"),
                "REINDEX testTable");
        winqEqual(new StatementReindex().reindexTable("testTable").of("testSchema"),
                "REINDEX testSchema.testTable");
        winqEqual(new StatementReindex().reindex("testIndex"),
                "REINDEX testIndex");
        winqEqual(new StatementReindex().reindexCollation("testCollation"),
                "REINDEX testCollation");
    }
}
