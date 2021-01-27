@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
 
 /*------------------------------------------------------------------------
    File        : Books
    Purpose     : Here are diffrent methods for creating, deleting, searching and updating book records.
                  Also included method for creating a book Id.
    Syntax      : 
    Description : 
    Author(s)   : Kristjan T.
    Created     : Wed Jan 20 23:35:00 EET 2021
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Books: 
    
    DEFINE TEMP-TABLE addBook LIKE Book.  //Book is table name here
    DEFINE TEMP-TABLE getBook LIKE Book.
    DEFINE TEMP-TABLE updateBook LIKE Book.
    
    DEFINE DATASET bookDataSet FOR updateBook.

    
    /*------------------------------------------------------------------------------
     Purpose: Create a new book entry with given fields to database.
     Notes: 
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID CreateBook( INPUT bookHeadline AS CHARACTER, bookAuthor AS CHARACTER, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        CREATE addBook.   //Creating here addBook temp-table
            
        ASSIGN 
            addBook.Id       = GetNewBookId()
            addBook.Headline = bookHeadline
            addBook.Author   = bookAuthor
            addBook.Loaned_out = FALSE.

        BUFFER-COPY addBook TO Book.  //Here we copy temp-table to Book database table
        
        //Feedback to client
        successMessage = "Record created!".
        success = TRUE.

        RETURN.

    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Get all book records from database.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID GetBooks( OUTPUT TABLE getBook, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        EMPTY TEMP-TABLE getBook.  //Empty temp-table to be sure that there is no more data left when we start filling it up
        
        //Looping through Book table
        FOR EACH Book NO-LOCK:
            
            CREATE getBook.   //Building temp-table
            BUFFER-COPY Book TO getBook.   //Lets fill temp-table with database records
            
        END. 
        
        //Feedback to client
        successMessage = "Records fetched successfully!".
        success = TRUE.
        
    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Get a single book from database. You can search it by book Id, Headline or Author.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID GetBook( INPUT bookId AS INTEGER, INPUT bookHeadline AS CHARACTER, INPUT bookAuthor AS CHARACTER, OUTPUT TABLE getBook, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        EMPTY TEMP-TABLE getBook.
        
        FIND FIRST Book WHERE Book.Id EQ bookId 
                           OR Book.Headline EQ bookHeadline 
                           OR Book.Author EQ bookAuthor NO-LOCK NO-ERROR.
        
        IF AVAILABLE Book THEN 
        DO:       
            CREATE getBook.
            BUFFER-COPY Book TO getBook.
            
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
     Purpose: Update book status at library. Can also update other book columns.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID UpdateBook( INPUT bookId AS INTEGER, INPUT DATASET bookDataSet, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        FIND FIRST updateBook.    //First find from temp-table
        
        FIND FIRST Book WHERE Book.Id EQ bookId EXCLUSIVE-LOCK NO-ERROR.  //EXCLUSIVE-LOCK - I can modify when I'm on entry
        
        ASSIGN
            updateBook.Id = bookId.
        
        IF AVAILABLE Book THEN 
        DO:    
            BUFFER-COPY updateBook TO Book.
            successMessage = "Record updated!".
            success = TRUE.
            
        END. 
        ELSE 
        DO: 
            successMessage = "Record not found!".
            success = FALSE.
        END.

    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose: Delete a book record from database. You can search it by book Id, Headline or Author.
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID DeleteBook( INPUT bookId AS INTEGER, INPUT bookHeadline AS CHARACTER, INPUT bookAuthor AS CHARACTER, OUTPUT successMessage AS CHARACTER, OUTPUT success AS LOGICAL ):
        
        FIND FIRST Book WHERE Book.Id EQ bookId 
                           OR Book.Headline EQ bookHeadline 
                           OR Book.Author EQ bookAuthor EXCLUSIVE-LOCK NO-ERROR.
        
        IF AVAILABLE Book THEN 
        DO:    
            DELETE Book.
            successMessage = "Book removed successfully!".
            success = TRUE.    
        END. 
        ELSE 
        DO: 
            successMessage = "Book not found!".
            success = FALSE.   
        END.

    END METHOD.


    /*------------------------------------------------------------------------------
     Purpose: Generate new Id for every book.
     Notes: Every Id should be unique.
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC INTEGER GetNewBookId( ):
        
        DEFINE VARIABLE bookId AS INTEGER INIT 0.
            
        FIND LAST Book NO-LOCK NO-ERROR.   //Finding last book entry at database
        
        IF AVAILABLE Book THEN 
        DO: 
            bookId = Book.Id.
        END.
        
        //If some books are deleted meanwhile, it's possible that the last book don't have the highest Id
        REPEAT:    
            
            FIND FIRST Book WHERE Book.Id = bookId + 1 NO-LOCK NO-ERROR.     
            bookId = bookId + 1.       
            IF NOT AVAILABLE Book THEN LEAVE.
                      
        END.
            
        RETURN bookId.

    END METHOD.
    
    
END CLASS.
