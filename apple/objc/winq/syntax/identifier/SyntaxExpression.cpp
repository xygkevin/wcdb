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

#include <WCDB/Syntax.h>
#include <WCDB/SyntaxAssertion.hpp>
#include <WCDB/SyntaxEnum.hpp>

namespace WCDB {

template<>
constexpr const char*
Enum::description(const Syntax::Expression::UnaryOperator& unaryOperator)
{
    switch (unaryOperator) {
    case Syntax::Expression::UnaryOperator::Negative:
        return "-";
    case Syntax::Expression::UnaryOperator::Positive:
        return "+";
    case Syntax::Expression::UnaryOperator::Tilde:
        return "~";
    case Syntax::Expression::UnaryOperator::Not:
        return "NOT";
    case Syntax::Expression::UnaryOperator::Null:
        return "NULL";
    }
}

template<>
constexpr const char*
Enum::description(const Syntax::Expression::BinaryOperator& binaryOperator)
{
    switch (binaryOperator) {
    case Syntax::Expression::BinaryOperator::Concatenate:
        return "||";
    case Syntax::Expression::BinaryOperator::Multiply:
        return "*";
    case Syntax::Expression::BinaryOperator::Divide:
        return "/";
    case Syntax::Expression::BinaryOperator::Modulo:
        return "%";
    case Syntax::Expression::BinaryOperator::Plus:
        return "+";
    case Syntax::Expression::BinaryOperator::Minus:
        return "-";
    case Syntax::Expression::BinaryOperator::LeftShift:
        return "<<";
    case Syntax::Expression::BinaryOperator::RightShift:
        return ">>";
    case Syntax::Expression::BinaryOperator::BitwiseAnd:
        return "&";
    case Syntax::Expression::BinaryOperator::BitwiseOr:
        return "|";
    case Syntax::Expression::BinaryOperator::Less:
        return "<";
    case Syntax::Expression::BinaryOperator::LessOrEqual:
        return "<=";
    case Syntax::Expression::BinaryOperator::Greater:
        return ">";
    case Syntax::Expression::BinaryOperator::GreaterOrEqual:
        return ">=";
    case Syntax::Expression::BinaryOperator::Equal:
        return "==";
    case Syntax::Expression::BinaryOperator::NotEqual:
        return "!=";
    case Syntax::Expression::BinaryOperator::Is:
        return "IS";
    case Syntax::Expression::BinaryOperator::And:
        return "AND";
    case Syntax::Expression::BinaryOperator::Or:
        return "OR";
    case Syntax::Expression::BinaryOperator::Like:
        return "LIKE";
    case Syntax::Expression::BinaryOperator::GLOB:
        return "GLOB";
    case Syntax::Expression::BinaryOperator::RegExp:
        return "REGEXP";
    case Syntax::Expression::BinaryOperator::Match:
        return "MATCH";
    }
}

namespace Syntax {

Expression::~Expression() = default;

#pragma mark - Identifier
Identifier::Type Expression::getType() const
{
    return type;
}

static void
streamAutoParenthesesExpression(std::ostringstream& stream, const Expression& expression)
{
    bool parentheses;
    switch (expression.switcher) {
    case Expression::Switch::LiteralValue:
    case Expression::Switch::BindParameter:
    case Expression::Switch::Column:
    case Expression::Switch::Function:
    case Expression::Switch::Cast:
    case Expression::Switch::In:
    case Expression::Switch::Exists:
    case Expression::Switch::Case:
    case Expression::Switch::RaiseFunction:
    case Expression::Switch::Window:
    case Expression::Switch::Expressions:
    case Expression::Switch::Select:
        parentheses = false;
        break;
    case Expression::Switch::UnaryOperation:
    case Expression::Switch::BinaryOperation:
    case Expression::Switch::Collate:
    case Expression::Switch::Between:
        parentheses = true;
        break;
    }
    if (parentheses) {
        stream << "(";
    }
    stream << expression;
    if (parentheses) {
        stream << ")";
    }
}

bool Expression::describle(std::ostringstream& stream) const
{
    switch (switcher) {
    case Switch::LiteralValue:
        stream << literalValue;
        break;
    case Switch::BindParameter:
        stream << bindParameter;
        break;
    case Switch::Column:
        if (!table.empty()) {
            if (!schema.empty()) {
                stream << schema << ".";
            }
            stream << table << ".";
        }
        stream << column;
        break;
    case Switch::UnaryOperation: {
        WCTSyntaxRemedialAssert(expressions.size() == 1);
        switch (unaryOperator) {
        case UnaryOperator::Null:
            streamAutoParenthesesExpression(stream, *expressions.begin());
            stream << space;
            if (isNot) {
                stream << "NOT";
            } else {
                stream << "IS";
            }
            stream << unaryOperator;
            break;
        case UnaryOperator::Not:
            stream << unaryOperator << space;
            streamAutoParenthesesExpression(stream, *expressions.begin());
            break;
        case UnaryOperator::Positive:
        case UnaryOperator::Negative:
        case UnaryOperator::Tilde:
            stream << unaryOperator;
            streamAutoParenthesesExpression(stream, *expressions.begin());
            break;
        }
        break;
    }
    case Switch::BinaryOperation:
        switch (binaryOperator) {
        case Syntax::Expression::BinaryOperator::Concatenate:
        case Syntax::Expression::BinaryOperator::Multiply:
        case Syntax::Expression::BinaryOperator::Divide:
        case Syntax::Expression::BinaryOperator::Modulo:
        case Syntax::Expression::BinaryOperator::Plus:
        case Syntax::Expression::BinaryOperator::Minus:
        case Syntax::Expression::BinaryOperator::LeftShift:
        case Syntax::Expression::BinaryOperator::RightShift:
        case Syntax::Expression::BinaryOperator::BitwiseAnd:
        case Syntax::Expression::BinaryOperator::BitwiseOr:
        case Syntax::Expression::BinaryOperator::Less:
        case Syntax::Expression::BinaryOperator::LessOrEqual:
        case Syntax::Expression::BinaryOperator::Greater:
        case Syntax::Expression::BinaryOperator::GreaterOrEqual:
        case Syntax::Expression::BinaryOperator::Equal:
        case Syntax::Expression::BinaryOperator::NotEqual:
        case Syntax::Expression::BinaryOperator::And:
        case Syntax::Expression::BinaryOperator::Or:
            WCTSyntaxRemedialAssert(expressions.size() == 2);
            streamAutoParenthesesExpression(stream, *expressions.begin());
            stream << space << binaryOperator << space;
            streamAutoParenthesesExpression(stream, *(++expressions.begin()));
            break;
        case Syntax::Expression::BinaryOperator::Is:
            WCTSyntaxRemedialAssert(expressions.size() == 2);
            // Extra parentheses to ensure the correctness of operator precedence
            streamAutoParenthesesExpression(stream, *expressions.begin());
            stream << space << binaryOperator;
            if (isNot) {
                stream << " NOT";
            }
            stream << space;
            streamAutoParenthesesExpression(stream, *(++expressions.begin()));
            break;
        case Syntax::Expression::BinaryOperator::Like:
        case Syntax::Expression::BinaryOperator::GLOB:
        case Syntax::Expression::BinaryOperator::RegExp:
        case Syntax::Expression::BinaryOperator::Match: {
            WCTSyntaxRemedialAssert(expressions.size() == 2 + escape);
            auto iter = expressions.begin();
            streamAutoParenthesesExpression(stream, *iter);
            if (isNot) {
                stream << " NOT";
            }
            stream << space << binaryOperator << space;
            streamAutoParenthesesExpression(stream, *(++iter));
            if (escape) {
                stream << " ESCAPE ";
                streamAutoParenthesesExpression(stream, *(++iter));
            }
            break;
        }
        }
        break;
    case Switch::Function:
        stream << function << "(";
        if (!expressions.empty()) {
            if (distinct) {
                stream << "DISTINCT ";
            }
            stream << expressions;
        } else if (useWildcard) {
            stream << "*";
        }
        stream << ")";
        break;
    case Switch::Expressions:
        stream << "(" << expressions << ")";
        break;
    case Switch::Cast:
        WCTSyntaxRemedialAssert(expressions.size() == 1);
        stream << "CAST(" << *expressions.begin() << " AS " << castType << ")";
        break;
    case Switch::Collate:
        WCTSyntaxRemedialAssert(expressions.size() == 1);
        streamAutoParenthesesExpression(stream, *expressions.begin());
        stream << " COLLATE " << collation;
        break;
    case Switch::Between: {
        WCTSyntaxRemedialAssert(expressions.size() == 3);
        auto iter = expressions.begin();
        streamAutoParenthesesExpression(stream, *iter);
        if (isNot) {
            stream << " NOT";
        }
        stream << " BETWEEN ";
        streamAutoParenthesesExpression(stream, *++iter);
        stream << " AND ";
        streamAutoParenthesesExpression(stream, *++iter);
        break;
    }
    case Switch::In: {
        WCTSyntaxRemedialAssert(expressions.size() >= 1);
        auto iter = expressions.begin();
        stream << *iter;
        if (isNot) {
            stream << " NOT";
        }
        stream << " IN";
        switch (inSwitcher) {
        case SwitchIn::Empty:
            stream << "()";
            break;
        case SwitchIn::Select:
            WCTSyntaxRemedialAssert(select != nullptr);
            stream << "(" << *select.get() << ")";
            break;
        case SwitchIn::Expressions: {
            stream << "(";
            bool comma = false;
            while (++iter != expressions.end()) {
                if (comma) {
                    stream << ", ";
                } else {
                    comma = true;
                }
                stream << *iter;
            }
            stream << ")";
            break;
        }
        case SwitchIn::Table:
            stream << space;
            if (!schema.empty()) {
                stream << schema << ".";
            }
            stream << table;
            break;
        case SwitchIn::Function: {
            stream << space;
            if (!schema.empty()) {
                stream << schema << ".";
            }
            stream << function << "(";
            bool comma = false;
            while (++iter != expressions.end()) {
                if (comma) {
                    stream << ", ";
                } else {
                    comma = true;
                }
                stream << *iter;
            }
            stream << ")";
            break;
        }
        }
        break;
    }
    case Switch::Exists:
        WCTSyntaxRemedialAssert(select != nullptr);
        if (isNot) {
            stream << "NOT ";
        }
        stream << "EXISTS(" << *select.get() << ")";
        break;
    case Switch::Select:
        WCTSyntaxRemedialAssert(select != nullptr);
        stream << "(" << *select.get() << ")";
        break;
    case Switch::Case: {
        WCTSyntaxRemedialAssert(expressions.size() >= hasCase + 2 + hasElse);
        WCTSyntaxRemedialAssert((expressions.size() - hasCase - hasElse) % 2 == 0);
        auto iter = expressions.begin();
        stream << "CASE ";
        if (hasCase) {
            stream << *iter << space;
            ++iter;
        }
        do {
            stream << "WHEN " << *iter;
            ++iter;
            stream << " THEN " << *iter << space;
            ++iter;
        } while (std::distance(iter, expressions.end()) > hasElse);
        if (hasElse) {
            stream << "ELSE " << *iter << space;
        }
        stream << "END";
        break;
    }
    case Switch::RaiseFunction:
        stream << raiseFunction;
        break;
    case Switch::Window:
        stream << function << "(";
        if (!expressions.empty()) {
            stream << expressions;
        } else if (useWildcard) {
            stream << "*";
        }
        stream << ")";
        if (filter.isValid()) {
            stream << space << filter;
        }
        stream << " OVER";
        if (windowName.empty()) {
            stream << windowDef;
        } else {
            stream << space << windowName;
        }
        break;
    }
    return true;
}

void Expression::iterate(const Iterator& iterator, bool& stop)
{
    Identifier::iterate(iterator, stop);
    switch (switcher) {
    // one expression
    case Switch::UnaryOperation:
    case Switch::Collate:
        WCTIterateRemedialAssert(expressions.size() == 1);
        expressions.begin()->iterate(iterator, stop);
        break;

    // two expressions
    case Switch::BinaryOperation:
        switch (binaryOperator) {
        case Syntax::Expression::BinaryOperator::Concatenate:
        case Syntax::Expression::BinaryOperator::Multiply:
        case Syntax::Expression::BinaryOperator::Divide:
        case Syntax::Expression::BinaryOperator::Modulo:
        case Syntax::Expression::BinaryOperator::Plus:
        case Syntax::Expression::BinaryOperator::Minus:
        case Syntax::Expression::BinaryOperator::LeftShift:
        case Syntax::Expression::BinaryOperator::RightShift:
        case Syntax::Expression::BinaryOperator::BitwiseAnd:
        case Syntax::Expression::BinaryOperator::BitwiseOr:
        case Syntax::Expression::BinaryOperator::Less:
        case Syntax::Expression::BinaryOperator::LessOrEqual:
        case Syntax::Expression::BinaryOperator::Greater:
        case Syntax::Expression::BinaryOperator::GreaterOrEqual:
        case Syntax::Expression::BinaryOperator::Equal:
        case Syntax::Expression::BinaryOperator::NotEqual:
        case Syntax::Expression::BinaryOperator::Is:
        case Syntax::Expression::BinaryOperator::And:
        case Syntax::Expression::BinaryOperator::Or:
            WCTIterateRemedialAssert(expressions.size() == 2);
            listIterate(expressions, iterator, stop);
            break;
        case Syntax::Expression::BinaryOperator::Like:
        case Syntax::Expression::BinaryOperator::GLOB:
        case Syntax::Expression::BinaryOperator::RegExp:
        case Syntax::Expression::BinaryOperator::Match: {
            WCTIterateRemedialAssert(expressions.size() == 2 + escape);
            listIterate(expressions, iterator, stop);
            break;
        }
        }
        break;
    // three expressions
    case Switch::Between: {
        WCTIterateRemedialAssert(expressions.size() == 3);
        listIterate(expressions, iterator, stop);
        break;
    }
    // expression list
    case Switch::Function:
    case Switch::Expressions:
    case Switch::Cast:
    case Switch::Case:
        listIterate(expressions, iterator, stop);
        break;
    // others
    case Switch::LiteralValue:
        recursiveIterate(literalValue, iterator, stop);
        break;
    case Switch::BindParameter:
        recursiveIterate(bindParameter, iterator, stop);
        break;
    case Switch::Column:
        if (!table.empty()) {
            recursiveIterate(schema, iterator, stop);
        }
        recursiveIterate(column, iterator, stop);
        break;
    case Switch::In: {
        WCTIterateRemedialAssert(expressions.size() >= 1);
        auto iter = expressions.begin();
        iter->iterate(iterator, stop);
        switch (inSwitcher) {
        case SwitchIn::Empty:
            break;
        case SwitchIn::Select:
            WCTIterateRemedialAssert(select != nullptr);
            select->iterate(iterator, stop);
            break;
        case SwitchIn::Expressions: {
            while (++iter != expressions.end()) {
                iter->iterate(iterator, stop);
            }
            break;
        }
        case SwitchIn::Table:
            recursiveIterate(schema, iterator, stop);
            break;
        case SwitchIn::Function: {
            recursiveIterate(schema, iterator, stop);
            while (++iter != expressions.end()) {
                iter->iterate(iterator, stop);
            }
            break;
        }
        }
        break;
    }
    case Switch::Exists:
        WCTIterateRemedialAssert(select != nullptr);
        select->iterate(iterator, stop);
        break;
    case Switch::Select:
        WCTIterateRemedialAssert(select != nullptr);
        select->iterate(iterator, stop);
        break;
    case Switch::RaiseFunction:
        recursiveIterate(raiseFunction, iterator, stop);
        break;
    case Switch::Window:
        listIterate(expressions, iterator, stop);
        if (filter.isValid()) {
            recursiveIterate(filter, iterator, stop);
        }
        if (windowName.empty()) {
            recursiveIterate(windowDef, iterator, stop);
        }
        break;
    }
}

} // namespace Syntax

} // namespace WCDB
