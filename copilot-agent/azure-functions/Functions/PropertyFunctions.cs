using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;

namespace PropertyManagementFunctions.Functions;

public class PropertyFunctions
{
    private readonly ILogger _logger;
    private readonly DatabaseHelper _db;

    public PropertyFunctions(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<PropertyFunctions>();
        var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString")
            ?? throw new InvalidOperationException("SqlConnectionString not configured");
        _db = new DatabaseHelper(connectionString);
    }

    [Function("GetProperties")]
    public async Task<HttpResponseData> GetProperties(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req)
    {
        _logger.LogInformation("GetProperties function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var parameters = new Dictionary<string, object?>
            {
                { "CityName", query["city"] },
                { "ProvinceName", query["province"] },
                { "Status", query["status"] },
                { "UnitType", query["unitType"] }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetAllProperties", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetProperties");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetPropertyById")]
    public async Task<HttpResponseData> GetPropertyById(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetPropertyById function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var propertyId = query["propertyId"];

            if (string.IsNullOrEmpty(propertyId))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId is required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", int.Parse(propertyId) }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetPropertyById", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetPropertyById");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("CreateProperty")]
    public async Task<HttpResponseData> CreateProperty(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("CreateProperty function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("buildingNo") || !data.ContainsKey("unitNumber"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "buildingNo and unitNumber are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "BuildingNo", data.GetValueOrDefault("buildingNo") },
                { "UnitNumber", data.GetValueOrDefault("unitNumber") },
                { "Address", data.GetValueOrDefault("address") },
                { "PostalCode", data.GetValueOrDefault("postalCode") },
                { "CityName", data.GetValueOrDefault("cityName") },
                { "ProvinceName", data.GetValueOrDefault("provinceName") },
                { "UnitType", data.GetValueOrDefault("unitType") },
                { "ManagementStartDate", data.GetValueOrDefault("managementStartDate") },
                { "LengthOfService", data.GetValueOrDefault("lengthOfService") },
                { "Status", data.GetValueOrDefault("status") },
                { "StorageLocker", data.GetValueOrDefault("storageLocker") },
                { "ParkingStall", data.GetValueOrDefault("parkingStall") },
                { "Remarks", data.GetValueOrDefault("remarks") },
                { "NewPropertyId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_CreateProperty", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateProperty");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("UpdateProperty")]
    public async Task<HttpResponseData> UpdateProperty(
        [HttpTrigger(AuthorizationLevel.Function, "put", "patch")] HttpRequestData req)
    {
        _logger.LogInformation("UpdateProperty function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("propertyId"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId is required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", data.GetValueOrDefault("propertyId") },
                { "Address", data.GetValueOrDefault("address") },
                { "PostalCode", data.GetValueOrDefault("postalCode") },
                { "CityName", data.GetValueOrDefault("cityName") },
                { "ProvinceName", data.GetValueOrDefault("provinceName") },
                { "UnitType", data.GetValueOrDefault("unitType") },
                { "ManagementStartDate", data.GetValueOrDefault("managementStartDate") },
                { "LengthOfService", data.GetValueOrDefault("lengthOfService") },
                { "Status", data.GetValueOrDefault("status") },
                { "StorageLocker", data.GetValueOrDefault("storageLocker") },
                { "ParkingStall", data.GetValueOrDefault("parkingStall") },
                { "Remarks", data.GetValueOrDefault("remarks") }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_UpdateProperty", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateProperty");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetPropertyDashboard")]
    public async Task<HttpResponseData> GetPropertyDashboard(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetPropertyDashboard function triggered");

        try
        {
            var result = await _db.ExecuteQuery("SELECT * FROM pm.vw_PropertyDashboard ORDER BY building_no, unit_number");

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetPropertyDashboard");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }
}
