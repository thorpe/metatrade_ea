//+------------------------------------------------------------------+
//|                                                       123123.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "libmysql.dll"
   int      mysql_init(int db); 
   int      mysql_errno(int TMYSQL); 
   int      mysql_real_connect(int TMYSQL,string host,string user,string password, string DB,int port,int socket,int clientflag); 
   int      mysql_real_query(int TMYSQL,string query,int length); 
   void     mysql_close(int TMYSQL); 
   int      mysql_store_result(int TMYSQL); 
   string   mysql_fetch_row(int result); 
   int      mysql_num_rows(int result); 
   void     mysql_free_result(int result); 
#import
 
string   Host       = "54.180.28.234";
string   User       = "giraffe_ai_user";
string   Password   = "BrmrBHacJeWuPyOlI9vZPPLQ";
string   Database   = "giraffe_ai_labs_socket";
int      Port       = 3306;
string   Socket     = "0";
int      ClientFlag = 0;

int      dbConnectId= 0, res, err;

int OnInit()
{
   connectToDB();
   
   string row; 
   
   string query= "SELECT * FROM fx_symbol_aud_usd limit 2";
   
   Print("query = " + query);
   int length=StringLen(query); 
   mysql_real_query(dbConnectId,query,length); 
   int result = mysql_store_result(dbConnectId); 
   int numOfRows = mysql_num_rows(result); 
   
   for (int i=0;i<numOfRows;i++) {
      row = mysql_fetch_row(result);
      Print(row);                             //--- Here in row is the result as string typo at the end of the string. In front are some symbols.
   }
   
   mysql_free_result(result);
   
   int myerr = mysql_errno(dbConnectId);
   
   if(myerr > 0) Print("error=",myerr);
   
   EventSetTimer(60);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   
   mysql_close(dbConnectId);
}

void OnTick()
{
   
   
}

void connectToDB() 
{ 
   dbConnectId= mysql_init(dbConnectId); 
   
   if(dbConnectId != 0) Print("allocated");
   
   res= mysql_real_connect(dbConnectId,Host,User,Password,Password,Port,Socket,ClientFlag); 
   err= GetLastError();
   
   if(res == dbConnectId) Print("connected"); 
   else Print("error=",dbConnectId," ",mysql_errno(dbConnectId)," "); 
   
   
} 
