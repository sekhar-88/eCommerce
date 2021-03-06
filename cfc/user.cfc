<!---
    Controller name: User.cfc
    THIS COMPONENT CONTAINS ALL USER RELATED FUNCTIONS LIKE VALIDATING THE USER WHILE LOGGING IN
    SETTING USER RELATED SESSION VARIABLES
    GETTING LOGGED IN STATUS
 --->


<cfcomponent extends="product" >
    <cfset VARIABLES.userDB = CreateObject("db.user_db")/>


<!--- retrns usere logged in or not in ajax --->
    <cffunction name="isUserLogggedin" returntype="boolean" returnFormat="json" access="remote" >
        <cfif session.loggedin>
                <cfreturn true/>
            <cfelse>
                <cfreturn false/>
        </cfif>
    </cffunction>


<!---
    getting the loggedin user in the javascript ajax calls
    Returns If a user is logged in or not. IF loggedin then his userid
--->
    <cffunction output="false" name="getLoggedUser" returnType="string"  returnFormat="json" access="remote">
        <cfif session.loggedin>
            <cfset user = {
                "userid" = "#session.User.UserId#",
                "loggedin" = "true"
                } />
        <cfelse>
            <cfset user = { "loggedin" = "false" } />
        </cfif>

        <cfset userS = serializeJSON(#user#) />
        <cfreturn #userS#/>
    </cffunction>




<!---
validate the login useer while logging in
return response
    as email error
    or password error
    depending on the situation
--->
    <cffunction name="validate" access="remote" output="false" returntype="struct" returnFormat="json">
        <cfargument name="email" type="string" required="true">
        <cfargument name="password" type="string" required="true">

            <cfset LOCAL.response = {
                    "status" = "true",
                    "errortype" = "",
                    "role" = ""
                }/>

                <cfset LOCAL.findUser = VARIABLES.userDB.getUserPassword( argumentcollection="#ARGUMENTS#" ) />
                <cfif LOCAL.findUser.recordcount>

                    <cfif LOCAL.findUser.PasswordHash EQ #HASH(ARGUMENTS.password)# >   <!--- login success --->

                        <!--- AUTHENTICATED  - get other user details from DB--->
                        <cfset LOCAL.result = VARIABLES.userDB.getUserDetails( argumentcollection="#ARGUMENTS#" ) />
                        <cfset sessionrotate() />

                        <!--- increase seession timeout once the user logs in  --->
                        <cfset THIS.sessionTimeout = CreateTimeSpan(0,0,5,0) />

                        <!--- set session variables for logged in user --->
                        <cfset session.User = {
                            UserId = "#LOCAL.result.UserId#",
                            UserName = "#LOCAL.result.FirstName#" & " " & "#LOCAL.result.LastName#",
                            UserEmail = "#LOCAL.result.Email#",
                            UserPhoneNo = "#LOCAL.result.PhoneNo#",
                            Role = "#LOCAL.result.Role#",
                            paymentDataChanged = false
                        } />

                            <cfset SESSION.loggedin="true" />
                            <cfset SESSION.User.checkout = { step = 0 }/>  <!--user has not checked out items --->

                            <!--- add session items to user cart --->
                            <cfloop array="#SESSION.cart#"  index="pid">
                                <cfset SUPER.addToCart(#pid#)/>
                            </cfloop>

                            <cfset LOCAL.response.status = "true" />
                            <cfset LOCAL.response.role = "#LOCAL.result.Role#"/>

                    <cfelse>
                        <cfset LOCAL.response.status = "false" />
                        <cfset LOCAL.response.errortype = "password" />
                    </cfif>

                <cfelse>
                    <cfset LOCAL.response.status = "false" >
                    <cfset LOCAL.response.errortype = "email" >
                </cfif>

                <cfreturn #LOCAL.response# />
    </cffunction>


<!---
    creating a new user with provided form fields in ajax
    with validation on server side
    it sends response {status , error }
    status for account creation status & error for which field has error
    like the email field already exists in database
--->
    <cffunction name="newUser" returntype="struct" access="remote"  returnformat="JSON" output = "true">
        <cfargument name="formSerialized" type="string" required="true" />

        <!--- deseriazed json string object for user registration  --->
        <cftry>

        <cfset LOCAL.form = deserializeJSON(ARGUMENTS.formSerialized) />

        <cfset LOCAL.response = {
                    status = true,
                    error = {}
                } />

            <cfif isValid('email', FORM.Email)>
                <cfset LOCAL.emailExists = VARIABLES.userDB.searchExistingEmails( email = "#LOCAL.form.Email#" ) />

                <cfif NOT LOCAL.emailExists>
                    <cfset LOCAL.createUserResponse = VARIABLES.userDB.createUser( form = #LOCAL.form# ) />

                <cfelse>
                    <!--- email error --->
                    <cfset LOCAL.response.status = false />
                    <cfset structInsert(LOCAL.response.error, 'Email', "This email is already associated with an account") />
                </cfif>

            <cfelse>
                <!--- email type not valid detected by coldfusion --->
                <cfset LOCAL.response.status = false />
                <cfset structInsert(LOCAL.response.error, 'Email', "Enter a valid Email Address") />

            </cfif>

                <cfcatch type = "any">
                    <cfdump var="#cfcatch#" />
                    <cfabort />
                </cfcatch>
            </cftry>

            <cfreturn LOCAL.response />
    </cffunction>

</cfcomponent>
