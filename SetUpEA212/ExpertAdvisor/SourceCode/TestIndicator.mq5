//+------------------------------------------------------------------+
//|                                                TestIndicator.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Test indicators in EA"
//+------------------------------------------------------------------+
//| Links to Indicators that will run in this EA                     |
//+------------------------------------------------------------------+
#define LinkToIndicators1 "\\OrFox\\212-03.ex5"
#define LinkToIndicators2 "\\OrFox\\Inditest01.ex5"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

// Nhập giá trị 
input int StopLoss   =  30;
input int TakeProfit =  100;
//--
int indu1,indu2, ST, TK;
double indi_212[], indi_test1[]; //P_Close,
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Triệu hồi Indicators
   indu1 = iCustom(NULL,PERIOD_CURRENT,LinkToIndicators1); // kích hoạt indicators 212
   indu2 = iCustom(NULL,PERIOD_CURRENT,LinkToIndicators2); // kích hoạt indicators làm mịn
//---
   ST = StopLoss;
   TK = TakeProfit;
   
   if(_Digits==3 || _Digits==5)
     {
      ST = ST*10;
      TK = TK*10;
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Giải phóng Indicatos khi thoát chương trình
   IndicatorRelease(indu1);
   IndicatorRelease(indu2);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//+------------------------------------------------------------------+
//| Kiểm tra đủ 60 cột                                               |
//+------------------------------------------------------------------+  
     if(Bars(_Symbol,_Period)<60) // Hàm dếm số nến, nếu không đủ 60 nến thì làm Alert, đủ rồi thì "Kiểm tra cột mới mỗi lần Hàm được gọi"
     {
      Alert("----Xx Chưa có đủ 60 nến, EA sẽ tạm dừng xX----");
      return;
     }
//+------------------------------------------------------------------+
//| Kiểm tra cột mới mỗi lần Hàm được gọi                            |
//+------------------------------------------------------------------+
   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;     
     // copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("Có nến mới ",New_Time[0],", Nến cũ là: ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("---->>> Không kiểm tra được nến mới <<<<----",GetLastError());
      ResetLastError();
      return;
     }
     
   if(IsNewBar==false) // Không có nến mới thì quay lại từ đầu
     {
      return;
     }
//+------------------------------------------------------------------+
//|Đếm đủ 60 nến để làm tiếp                                         |
//+------------------------------------------------------------------+      
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("----Xx Chưa có đủ 60 nến, EA sẽ tạm dừng đến khi đủ xX----");
      return;
     }
//+--------------------------------------------------------------------+
//|Đưa thông số các mốc nến vào mảng 1 chiều đề tham chiếu cho mua-bán |
//+--------------------------------------------------------------------+ 
   MqlTick GiaMoi;      
   MqlTradeRequest mrequest;  
   MqlTradeResult mresult;    
   MqlRates mrate[];          
   ZeroMemory(mrequest);
   
   ArraySetAsSeries(mrate,true); // Sắp xếp mảng giảm dần
   ArraySetAsSeries(indi_212,true);
   ArraySetAsSeries(indi_test1,true);

      if(!SymbolInfoTick(_Symbol,GiaMoi))
       {
        Alert("----> Không lấy được dữ liệu Giá mới <----     Error; ",GetLastError());
        ResetLastError();
        return;
       }
      if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
      {
         Alert("----> Không lấy được dữ liệu giao dịch <----     Error; ",GetLastError());
         ResetLastError();
       return;
      } 
/*          
     if(CopyBuffer(indu1,0,0,6,indi_212)<0)
       {
        Alert("----> Indicator 212 bị lỗi thu thập dữ liệu <----     Error; ",GetLastError());
        ResetLastError();
        return;
       }*/
     if(CopyBuffer(indu2,0,0,8,indi_test1)<0)
       {
        Alert("----> Indicator Làm Mịn bị lỗi thu thập dữ liệu <----     Error; ",GetLastError());
        ResetLastError();
        return;
       }       
//+------------------------------------------------------------------+
//|Điều kiện xét để lệnh mua đươc tiến hành                          |
//+------------------------------------------------------------------+ 
/* 
   bool Buy_opened=false;  // Điều kiện Mua vào cơ bản của EA lúc khởi tạo và khi đang chờ giao dịch tiếp theo
   bool Sell_opened=false; // Điều kiện Bán ra cơ bản của EA lúc khởi tạo và khi đang chờ giao dịch tiếp theo

   if(PositionSelect(_Symbol)==true) // Tìm được vị trí giao dịch
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         Buy_opened=true;  // Xác nhận vị trí đang mở bán
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         Sell_opened=true; // Xác nhận vị trí đang mở mua
        }
     }
  
     P_Close = mrate[1].close; //--- Tìm giá đóng cửa từ Biểu đồ (Chart)
*/
//+------------------------------------------------------------------+
//|Điều kiện Mua để lệnh bán đươc tiến hành                          |
//+------------------------------------------------------------------+  
// indi_212             indi_test1

//bool Mua_1 = (indi_test1[1]<indi_test1[0] && indi_test1[2]<indi_test1[1]); //indi Mịn bị giảm
//bool Mua_2 = (P_Close>indi_test1[1]);
bool Mua_3 = (indi_test1[7]>indi_test1[6] && indi_test1[6]<indi_test1[5] && indi_test1[5]<indi_test1[4] && indi_test1[4]>indi_test1[3] && indi_test1[3]<indi_test1[2] && indi_test1[2]<indi_test1[1]);
bool Mua_4 = (indi_test1[1]<indi_test1[2] && indi_test1[2]<indi_test1[3] && indi_test1[3]<indi_test1[4] && indi_test1[4]<indi_test1[5]);

     if(Mua_3 || Mua_4)
     {  
           ZeroMemory(mrequest);
            mrequest.action    = TRADE_ACTION_DEAL;
            mrequest.type      = ORDER_TYPE_BUY;
            //mrequest.price     = NormalizeDouble(GiaMoi.ask,_Digits);
            mrequest.price     = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            mrequest.sl        = NormalizeDouble(GiaMoi.ask - ST*_Point,_Digits);
            mrequest.tp        = NormalizeDouble(GiaMoi.ask + TK*_Point,_Digits);
            mrequest.symbol    = Symbol();
            mrequest.volume    = 0.1;
            mrequest.deviation = 100;
            mrequest.magic     = 123456;
            mrequest.type_filling = ORDER_FILLING_FOK;   
            //OrderSend(mrequest,mresult);             
            if(!OrderSend(mrequest,mresult)) Alert("----x$x Không thể thực hiện Giao Dịch Mua x$x---- Error: ",GetLastError());
            else PrintFormat("Tham gia giao dịch mua\n Số ticket: %I64u\tMã Order: %I64u\n   Mã lệnh retcode: %u   ",mresult.deal,mresult.order,mresult.retcode);
     }
//+------------------------------------------------------------------+
//|Điều kiện Bán để lệnh bán đươc tiến hành                          |
//+------------------------------------------------------------------+  
bool Ban_1 = (indi_test1[7]<indi_test1[6] && indi_test1[6]>indi_test1[5] && indi_test1[5]>indi_test1[4] && indi_test1[4]<indi_test1[3] && indi_test1[3]>indi_test1[2] && indi_test1[2]>indi_test1[1]);
bool Ban_2 = (indi_test1[1]>indi_test1[2] && indi_test1[2]>indi_test1[3] && indi_test1[3]>indi_test1[4] && indi_test1[4]>indi_test1[5]);

   if(Ban_1 || Ban_2)
     {
            ZeroMemory(mrequest);
            mrequest.action    = TRADE_ACTION_DEAL;
            mrequest.type      = ORDER_TYPE_SELL;            
            //mrequest.price     = NormalizeDouble(GiaMoi.bid,_Digits);
            mrequest.price     = SymbolInfoDouble(Symbol(),SYMBOL_BID);
            mrequest.sl        = NormalizeDouble(GiaMoi.bid + ST*_Point,_Digits);
            mrequest.tp        = NormalizeDouble(GiaMoi.bid - TK*_Point,_Digits);
            mrequest.symbol    = Symbol();
            mrequest.volume    = 0.1;
            mrequest.deviation = 100;
            mrequest.magic     = 123456;
            mrequest.type_filling = ORDER_FILLING_FOK;   
            //OrderSend(mrequest,mresult);             
            if(!OrderSend(mrequest,mresult)) Alert("----x$x Không thể thực hiện Giao Dịch Bán x$x---- Error: ",GetLastError());
            else PrintFormat("Tham gia giao dịch bán\n Số ticket: %I64u\tMã Order: %I64u\n   Mã lệnh retcode: %u   ",mresult.deal,mresult.order,mresult.retcode);         
     }
    
  }
//+------------------------------------------------------------------+
//|                     KẾT THÚC EXPERT ADVISOR                      |
//+------------------------------------------------------------------+  

/*
 MqlTradeRequest request= {0};
      MqlTradeResult  result= {0};
   if(POSITION_SL==0.5)
     {     
      request.action    = TRADE_ACTION_DEAL;
      request.symbol    = Symbol();
      request.volume    = 0.2;
      request.type      = ORDER_TYPE_BUY;
      request.price     = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      request.deviation = 5;
      request.magic     = 123456;
         if(!OrderSend(request,result)) Alert("Can't Buy (error: %d )",GetLastError());
         else PrintFormat("Buy=%I64u   retcode=%u    order=%I64u",result.deal,result.retcode,result.order);
     }
*/