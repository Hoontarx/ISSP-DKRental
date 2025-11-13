using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;

namespace PropertyManagementFunctions.Functions;

public class TenantFunctions
{
    private readonly ILogger _logger;
    private readonly DatabaseHelper _db;

    public TenantFunctions(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<TenantFunctions>();
        var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString")
            ?? throw new InvalidOperationException("SqlConnectionString not configured");
        _db = new DatabaseHelper(connectionString);
    }

    [Function("GetActiveTenancies")]
    public async Task<HttpResponseData> GetActiveTenancies(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetActiveTenancies function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", query["propertyId"] != null ? int.Parse(query["propertyId"]!) : null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetActiveTenancies", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetActiveTenancies");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("SearchTenants")]
    public async Task<HttpResponseData> SearchTenants(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("SearchTenants function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var parameters = new Dictionary<string, object?>
            {
                { "FirstName", query["firstName"] },
                { "LastName", query["lastName"] },
                { "Email", query["email"] },
                { "PhoneNumber", query["phoneNumber"] }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_SearchTenants", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in SearchTenants");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("CreateTenancy")]
    public async Task<HttpResponseData> CreateTenancy(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("CreateTenancy function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("propertyId") || !data.ContainsKey("leaseStartDate"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId and leaseStartDate are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", data.GetValueOrDefault("propertyId") },
                { "LeaseStartDate", data.GetValueOrDefault("leaseStartDate") },
                { "LeaseEndDate", data.GetValueOrDefault("leaseEndDate") },
                { "LeaseStatus", data.GetValueOrDefault("leaseStatus", "Active") },
                { "Term", data.GetValueOrDefault("term") },
                { "SecurityDeposit", data.GetValueOrDefault("securityDeposit") },
                { "SecurityDepositDate", data.GetValueOrDefault("securityDepositDate") },
                { "PetDeposit", data.GetValueOrDefault("petDeposit") },
                { "PetDepositDate", data.GetValueOrDefault("petDepositDate") },
                { "LastRentIncrease", data.GetValueOrDefault("lastRentIncrease") },
                { "InsurancePolicyNumber", data.GetValueOrDefault("insurancePolicyNumber") },
                { "InsuranceStartDate", data.GetValueOrDefault("insuranceStartDate") },
                { "InsuranceEndDate", data.GetValueOrDefault("insuranceEndDate") },
                { "NewTenancyId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_CreateTenancy", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateTenancy");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("AddTenant")]
    public async Task<HttpResponseData> AddTenant(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("AddTenant function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("tenancyId") || !data.ContainsKey("firstName") || !data.ContainsKey("lastName"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "tenancyId, firstName, and lastName are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "TenancyId", data.GetValueOrDefault("tenancyId") },
                { "FirstName", data.GetValueOrDefault("firstName") },
                { "LastName", data.GetValueOrDefault("lastName") },
                { "Email", data.GetValueOrDefault("email") },
                { "Mobile", data.GetValueOrDefault("mobile") },
                { "NewTenantId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_AddTenant", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in AddTenant");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("UpdateTenant")]
    public async Task<HttpResponseData> UpdateTenant(
        [HttpTrigger(AuthorizationLevel.Function, "put", "patch")] HttpRequestData req)
    {
        _logger.LogInformation("UpdateTenant function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("tenantId"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "tenantId is required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "TenantId", data.GetValueOrDefault("tenantId") },
                { "FirstName", data.GetValueOrDefault("firstName") },
                { "LastName", data.GetValueOrDefault("lastName") },
                { "Email", data.GetValueOrDefault("email") },
                { "Mobile", data.GetValueOrDefault("mobile") }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_UpdateTenant", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateTenant");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetExpiringLeases")]
    public async Task<HttpResponseData> GetExpiringLeases(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetExpiringLeases function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var daysAhead = query["daysAhead"] != null ? int.Parse(query["daysAhead"]!) : 90;

            var parameters = new Dictionary<string, object?>
            {
                { "DaysAhead", daysAhead }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetExpiringLeases", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetExpiringLeases");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }
}
