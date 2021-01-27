@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
 
 /*------------------------------------------------------------------------
    File        : Lenders
    Purpose     : Here are diffrent methods for creating and searching lender records.
                  Also included method for creating a lender Id.
    Syntax      : 
    Description : 
    Author(s)   : Kristjan T.
    Created     : Thu Jan 21 16:35:12 EET 2021
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Lender: 
    
    DEFINE TEMP-TABLE addLender LIKE Lender.
    DEFINE TEMP-TABLE getLender LIKE Lender.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Create a new lender entry with given fields to database.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID CreateLender( INPUT lenderName AS CHARACTER, INPUT lenderAuthenticated AS LOGICAL, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        CREATE addLender.   //Creating here addLender temp-table
        
        ASSIGN 
            addLender.Id   = GetNewLenderId()
            addLender.Name = lenderName
            addLender.Authenticated = lenderAuthenticated.
        
        BUFFER-COPY addLender TO Lender.  //Here we copy temp-table to Lender database table
        
        //Feedback to client
        successMessage = "Record created!".
        success = TRUE.

    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Get all lender records from database. You can search it by book Id, Headline or Author.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID GetLenders( OUTPUT TABLE getLender, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        EMPTY TEMP-TABLE getLender.
        
        //Looping through Lender table
        FOR EACH Lender NO-LOCK:
            
            CREATE getLender.   //Building temp-table
            BUFFER-COPY Lender TO getLender.   //Lets fill temp-table with database records
            
        END. 
        
        //Feedback to client
        successMessage = "Records fetched successfully!".
        success = TRUE.

    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Get a single lender from database. You can search it by lender Id or Name.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID GetLender( INPUT lenderId AS INTEGER, INPUT lenderName AS CHARACTER, OUTPUT TABLE getLender, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        EMPTY TEMP-TABLE getLender.
        
        FIND FIRST Lender WHERE Lender.Id EQ lenderId 
                             OR Lender.Name EQ lenderName NO-LOCK NO-ERROR.
        
        IF AVAILABLE Lender THEN 
        DO:       
            CREATE getLender.
            BUFFER-COPY Lender TO getLender.
            
            //Some feedback to client
            successMessage = "Record found successfully!".
            success = TRUE.   
        END. 
        ELSE 
        DO:      
            //Some feedback to client
            successMessage = "Book not found!".
            success = FALSE.
        END.

    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose: Generate new Id for every lender.
     Notes: Every Id should be unique.
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC INTEGER GetNewLenderId( ):
        
        DEFINE VARIABLE lenderId AS INTEGER INIT 0.
            
        FIND LAST Lender NO-LOCK NO-ERROR.   //Finding last lender entry at database
        
        IF AVAILABLE Lender THEN 
        DO: 
            lenderId = Lender.Id.
        END.
        
        //If some lenders are deleted meanwhile, it's possible that last lender don't have the highest Id
        REPEAT:    
            
            FIND FIRST Lender WHERE Lender.Id = lenderId + 1 NO-LOCK NO-ERROR.     
            lenderId = lenderId + 1.       
            IF NOT AVAILABLE Lender THEN LEAVE.
                      
        END.
            
        RETURN lenderId.

    END METHOD.
    
    
END CLASS.