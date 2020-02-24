module sbylib.graphics.util.member;

import std : isAggregateType, Filter, staticMap, AliasSeq;

template getMembersByUDA(Aggregate, alias UDA) {
    enum condition(alias memberInfo) = memberInfo.hasUDA!(UDA);
    alias getMembersByUDA = Filter!(condition, getMembers!(Aggregate));
}

template getMembers(Aggregate) {
    static assert(isAggregateType!Aggregate);

    alias getMembers = staticMap!(getMembersImpl, __traits(allMembers, Aggregate));

    enum Kind {
        Field,
        Type,
    }

    template getMembersImpl(string memberName) {
        static if (memberName == "__dtor") {
            alias getMembersImpl = AliasSeq!();
        } else {
            struct Result {
                import std : stdHasUDA = hasUDA, stdGetUDAs = getUDAs;

                alias member = __traits(getMember, Aggregate, memberName);

                enum name = memberName;

                static if (is(typeof(member))) {
                    enum kind = Kind.Field;
                    alias type = typeof(member);
                    enum hasType = true;
                } else static if (is(member)) {
                    enum kind = Kind.Type;
                    enum hasType = false;
                } else {
                    static assert(false);
                }

                static if (is(typeof(__traits(getAttributes, member)))) {
                    alias attributes = __traits(getAttributes, member);
                    enum hasAttributes = true;

                    enum hasUDA(alias UDA) = stdHasUDA!(member, UDA);
                    enum getUDAs(alias UDA) = stdGetUDAs!(member, UDA);

                    template getUDA(alias UDA) {
                        enum UDAs = getUDAs!(UDA);
                        static assert(UDAs.length == 1);
                        enum getUDA = UDAs[0];
                    }
                } else {
                    enum hasAttributes = false;
                    enum hasUDA(alias UDA) = false;
                    enum getUDAs(alias UDA) = false;
                    enum getUDA(alias UDA) = false;
                }
            }

            alias getMembersImpl = Result;
        }
    }
}
