<!---
    Component Name: cart_db.cfc
    This Model Contains Database Operations related to CART Page..
--->

<cfcomponent>

    <!--- returns cart item details with their respective product names --->
    <cffunction name="queryProductsFromUserCart" returntype="query" access="public"   >
        <cfquery name="LOCAL.items">
                SELECT c.CartId, c.UserId, c.ProductId, c.Qty, c.TotalPrice, c.DiscountAmount, p.Name
                FROM [Cart] c
                INNER JOIN [Product] p
                ON c.ProductId = p.ProductId
                WHERE c.UserId = #SESSION.User.UserId#
        </cfquery>
        <cfreturn LOCAL.items />
    </cffunction>


    <cffunction name="queryProductsFromSessionCart" returntype="query" access="public"   >
        <cfset LOCAL.cart_list = ArrayToList(SESSION.cart) />

        <cfquery name="LOCAL.products">
            SELECT p.ProductId, p.Name
            FROM [Product] p
            WHERE p.ProductId IN (   <cfqueryparam
                                    value = '#LOCAL.cart_list#'
                                    cfsqltype="cf_sql_integer"
                                    list = 'yes' >
                               )
        </cfquery>

        <cfreturn LOCAL.products />
    </cffunction>


    <cffunction name="removeItemFromUserCart" returntype="boolean" access = "public" >
        <cfargument name="pid" type="numeric" required="true" />
        <cfset LOCAL.response = false />
        <cftry >
            <cfquery name="removeItem">
                DELETE
                FROM [Cart]
                WHERE ProductId = #ARGUMENTS.pid# AND UserId = #SESSION.User.UserId#
            </cfquery>
            <cfset LOCAL.response = true />

            <cfcatch type = "DATABASE">
                <cflog file = "ShoppingDBlog" text="message: #cfcatch.message# , NativeErrorCode: #cfcatch.nativeErrorCode#" type="error"  />
                <cfset LOCAL.response = false />
            </cfcatch>
        </cftry>

        <cfreturn LOCAL.response/>
    </cffunction>

</cfcomponent>
