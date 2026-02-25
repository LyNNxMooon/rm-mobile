//End Points
const kEndPointForStockDetails = "/stock/{$kPathParamForBarcode}";
const kEndPointForStocktake = "/stock/update";
const kEndPointForShopList = "/shop/list";
const kEndPointForConnect = "/shop/connect";
const kEndPointForBulkStocktake = "/stock/update-bulk";
const kEndPointForStockList = "/stock/list";
const kEndPointForDiscover = "/discover";
const kEndPointForPairCode = "/paircode";
const kEndPointForParing = "/pair";
const kEndPointForShopfronts = "/shopfronts";
const kEndPointForConnectShopfront =
    "/shopfronts/{$kPathParamForShopfrontId}/connect";
const kEndPointForStockLookup = "/shopfronts/{$kPathParamForShopfrontId}/stock";
const kEndPointForShopfrontStockUpdate =
    "/shopfronts/{$kPathParamForShopfrontId}/stock/update";
const kEndPointForPictureUpload =
    "/shopfronts/{$kPathParamForShopfrontId}/pictures/{$kPathParamForStockId}";
const kEndPointForStocktakeInitCheck =
    "/shopfronts/{$kPathParamForShopfrontId}/stocktake/initcheck";
const kEndPointForStocktakeCommit =
    "/shopfronts/{$kPathParamForShopfrontId}/stocktake/commit";
const kEndPointForStocktakeBackup =
    "/shopfronts/{$kPathParamForShopfrontId}/stocktake/backup";
const kEndPointForStocktakeBackupLoad =
    "/shopfronts/{$kPathParamForShopfrontId}/stocktake/backup/{$kPathParamForFileName}";
const kEndPointForStocktakeLimit = "/stocktake/limit";
const kEndPointForValidate = "/validate";

//keys
const kPathParamForHostIP = "HostIP";
const kPathParamForBarcode = "Barcode";
const kPathParamForShopfrontId = "ShopfrontId";
const kPathParamForStockId = "StockId";
const kPathParamForFileName = "FileName";
const kQueryParamKeyForLastStockID = "lastStockId";
const kQueryParamKeyForPageSize = "pageSize";
