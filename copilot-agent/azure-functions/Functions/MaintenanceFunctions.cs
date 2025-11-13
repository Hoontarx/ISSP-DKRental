using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;

namespace PropertyManagementFunctions.Functions;

public class MaintenanceFunctions
{
    private readonly ILogger _logger;
    private readonly DatabaseHelper _db;

    public MaintenanceFunctions(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<MaintenanceFunctions>();
        var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString")
            ?? throw new InvalidOperationException("SqlConnectionString not configured");
        _db = new DatabaseHelper(connectionString);
    }

    [Function("GetMaintenanceRequests")]
    public async Task<HttpResponseData> GetMaintenanceRequests(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetMaintenanceRequests function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", query["propertyId"] != null ? int.Parse(query["propertyId"]!) : null },
                { "Status", query["status"] },
                { "AssignedTo", query["assignedTo"] }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetMaintenanceRequests", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetMaintenanceRequests");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("CreateMaintenance")]
    public async Task<HttpResponseData> CreateMaintenance(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("CreateMaintenance function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("propertyId") || !data.ContainsKey("description"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId and description are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", data.GetValueOrDefault("propertyId") },
                { "Description", data.GetValueOrDefault("description") },
                { "ActionPlan", data.GetValueOrDefault("actionPlan") },
                { "Status", data.GetValueOrDefault("status", "Open") },
                { "AssignedTo", data.GetValueOrDefault("assignedTo") },
                { "ContractorId", data.GetValueOrDefault("contractorId") },
                { "NewMaintenanceId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_CreateMaintenance", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateMaintenance");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("UpdateMaintenance")]
    public async Task<HttpResponseData> UpdateMaintenance(
        [HttpTrigger(AuthorizationLevel.Function, "put", "patch")] HttpRequestData req)
    {
        _logger.LogInformation("UpdateMaintenance function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("maintenanceId"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "maintenanceId is required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "MaintenanceId", data.GetValueOrDefault("maintenanceId") },
                { "Description", data.GetValueOrDefault("description") },
                { "ActionPlan", data.GetValueOrDefault("actionPlan") },
                { "Status", data.GetValueOrDefault("status") },
                { "AssignedTo", data.GetValueOrDefault("assignedTo") },
                { "ContractorId", data.GetValueOrDefault("contractorId") }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_UpdateMaintenance", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateMaintenance");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetInspections")]
    public async Task<HttpResponseData> GetInspections(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetInspections function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", query["propertyId"] != null ? int.Parse(query["propertyId"]!) : null },
                { "InspectionType", query["inspectionType"] },
                { "NeedInspection", query["needInspection"] }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetInspections", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetInspections");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("CreateInspection")]
    public async Task<HttpResponseData> CreateInspection(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("CreateInspection function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("propertyId") || !data.ContainsKey("inspectionType"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId and inspectionType are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", data.GetValueOrDefault("propertyId") },
                { "InspectionType", data.GetValueOrDefault("inspectionType") },
                { "LastInspectionDate", data.GetValueOrDefault("lastInspectionDate") },
                { "NeedInspection", data.GetValueOrDefault("needInspection") },
                { "InspectionNotes", data.GetValueOrDefault("inspectionNotes") },
                { "RepairsMaintenance", data.GetValueOrDefault("repairsMaintenance") },
                { "FollowUpDate", data.GetValueOrDefault("followUpDate") },
                { "NewInspectionId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_CreateInspection", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateInspection");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }
}
