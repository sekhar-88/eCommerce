<cfcomponent>

    <cfset VARIABLES.productDB = CreateObject("db.product_db")/>


<!--- This function updates the product details from editing the product in product details page --->
    <cffunction name = "updateProductDetails" returntype = "Any" access = "remote" >
        <cfargument name="productUpdate" type="struct" required = "true"  />
        <cfargument name="imagename" type="string" required = "true" />

        <cfinvoke method="updateProductDetails" component="#VARIABLES.productDB#"
            returnvariable="REQUEST.success" argumentcollection="#ARGUMENTS#"  />

        <cfreturn REQUEST.success />
    </cffunction>


    <cffunction name = "user_checkout" returntype = "boolean" returnformat = "json" output = "true" access = "remote">
        <cfargument name = "pid" type = "numeric" required = "true" />
          <cfset addedToCart = addToCart(arguments.pid)/>
          <cfreturn #addedToCart# />
    </cffunction>


<!--- HINT : this method is called while adding to cart by clicking "addtocart" or directy clicking on "buynow" button --->
    <cffunction name = "addToCart" returnType = "boolean" returnFormat = "json" access = "remote" output = "false">
        <cfargument name = "pid" type = "numeric" required = "true" />

            <cfif session.loggedin>
                <cfset userid = #session.User.UserId# />

                <!--- QUERY FOR ALREADY EXISTING PRODUCT --->
                <cfinvoke method = "queryCartForProduct" component = "#VARIABLES.productDB#"
                    returnvariable = "REQUEST.cart" pid = #ARGUMENTS.pid# />

                <cfif REQUEST.cart.recordCount >    <!--- in cart --->
                    <cfreturn true/>                <!--- THIS RETURN TRUE IS FOR sending (buynow) button that it is already in cart --->

                <cfelse>           <!--- not in cart --->
                    <cfset LOCAL.price = getPriceOfProduct(arguments.pid)/>
                    <cfinvoke method = "insertIntoCart" component = "#VARIABLES.productDB#"
                        returnvariable = "cart" pid = #ARGUMENTS.pid# price = "#LOCAL.price#" />

                    <!--- cart data changed --->
                    <cfset session.cartDataChanged = true/>;
                    <cfreturn true />
                </cfif>

            <cfelse>  <!---not logged in  ADD TO Session Cart--->
                <cfif ArrayContains(session.cart, #arguments.pid#)>
                    <cfreturn false/>
                <cfelse>
                    <cfset ArrayAppend(session.cart, #arguments.pid#) /> <!--- Store in Session --->
                    <cfset session.cartDataChanged = true/>
                    <cfreturn true />
                </cfif>
            </cfif>
    </cffunction>



    <cffunction name = "getProductsForSubCat" access = "remote" returntype = "Query" output = "false" >
        <cfargument name = "scat" required = "true" type = "numeric" output = "false" />

        <cfinvoke method = "queryProductsForSubCategory" component = "#VARIABLES.productDB#"
            returnvariable = "LOCAL.products" argumentcollection = "#ARGUMENTS#"  />

        <cfreturn #LOCAL.products#/>
    </cffunction>



    <cffunction name = "getPriceOfProduct" access = "remote" returntype = "boolean" output = "true">
        <cfargument name = "pid" required = "true" type = "numeric"/>
        <cfset LOCAL.ListPrice = 0 />

        <cfinvoke method = "getProduct" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.product" argumentcollection = "#ARGUMENTS#" />

        <cfreturn #REQUEST.product.ListPrice#/>
    </cffunction>



    <cffunction name = "fetchProductDetails" access = "remote" returntype = "query" output = "true">
        <cfargument name = "pid" required = "true" type = "numeric" />

        <cfinvoke method = "queryProductDetailsAndBrand" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.productDetails" pid = "#ARGUMENTS.pid#" />

        <cfreturn #REQUEST.productDetails#/>
    </cffunction>


    <cffunction name = "isProductInCart" returntype = "boolean" access = "public" >
        <cfargument name = "pid" type = "numeric" required = "true" />

        <cfset LOCAL.inCart = false/>

        <!--- get cart count for that product --->
        <cfif SESSION.loggedin >
            <cfinvoke method = "queryCartForProduct" component = "#VARIABLES.productDB#"
                returnvariable = "REQUEST.cart" pid = #ARGUMENTS.pid# />

                <cfif REQUEST.cart.recordCount>
                    <cfset LOCAL.inCart = true/>
                </cfif>
        <cfelse>
                <cfif ArrayContains(session.cart , #pid#)>
                    <cfset LOCAL.inCart = true />
                </cfif>
        </cfif>

        <cfreturn #LOCAL.inCart#/>
    </cffunction>


    <cffunction name = "getavailableProductQuantity" returntype = "numeric" access = "public"  >
        <cfargument name = "pid" type = "numeric" required = "true" />

        <cfinvoke method = "getProduct" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.product" argumentcollection = "#ARGUMENTS#"  />

        <cfreturn #REQUEST.product.Qty# />
    </cffunction>


    <cffunction name = "filterSubCategories" returntype = "Query" access = "remote"   >
        <cfargument name = "q" type = "string" required = "true"  />

        <cfset LOCAL.q = #Trim(ARGUMENTS.q)# />
        <cfset REReplace(LOCAL.q, "[^\w ]", "", "ALL") />

        <cfinvoke method = "getSubCategoryFilters" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.subcategoryFilters" q = #LOCAL.q#  />
        <cfreturn REQUEST.subCategoryFilters />
    </cffunction>


    <cffunction name = "filterBrands" returntype = "Query" access = "remote"  >
        <cfargument name = "scat" type = "numeric" required = "true" />
        <cftry>

            <cfinvoke method = "getBrandsFilter" component = "#VARIABLES.productDB#"
                returnvariable = "REQUEST.brandsFilter" scat = "#ARGUMENTS.scat#" />
        <cfcatch>
            <cfoutput>
                soryy an error type  = "#cfcatch.type#" occured
            </cfoutput>
        </cfcatch>
        </cftry>

        <cfreturn REQUEST.brandsFilter />
    </cffunction>

    <cffunction name = "hasProducts" returntype = "Query" access = "remote" >
        <cfargument name = "q" type = "string" required = "true" />
        <cfset LOCAL.q = #Trim(ARGUMENTS.q)# />

        <cfinvoke method = "queryProducts" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.products" q = #LOCAL.q# />

        <cfreturn REQUEST.products />
    </cffunction>

    <cffunction name = "addNewProduct" returntype = "boolean" access = "remote"  >
        <cfargument name = "form" type = "struct" required = "true" />
        <cfargument name = "imageName" type = "string" required = "true"  />

        <cfinvoke method = "addNewProductToDB" component = "#VARIABLES.productDB#"
            returnvariable = "REQUEST.success" argumentcollection = "#ARGUMENTS#"  />

        <cfreturn REQUEST.success />
    </cffunction>


<!--- simple function to fetch category name from the Subcategory ID --->
    <cffunction name="getSubCategoryName" returntype = "String" access="remote" >
        <cfargument name="scat" type="numeric" required = "true" />

        <cfinvoke method="getSubCategoryName" component="#VARIABLES.productDB#"
            returnvariable="REQUEST.subCategory" argumentcollection="#ARGUMENTS#" />

        <cfreturn REQUEST.subCategory.SubCategoryName />
    </cffunction>
</cfcomponent>
