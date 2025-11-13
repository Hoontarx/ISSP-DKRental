using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Net;

namespace PropertyManagementFunctions.Functions;

public class QueryFunctions
{
    private readonly ILogger _logger;
    private readonly DatabaseHelper _db;

    public QueryFunctions(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<QueryFunctions>();
        var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString")
            ?? throw new InvalidOperationException("SqlConnectionString not configured");
        _db = new DatabaseHelper(connectionString);
    }

    [Function("GetUpcomingEvents")]
    public async Task<HttpResponseData> GetUpcomingEvents(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetUpcomingEvents function triggered");

        try
        {
            var result = await _db.ExecuteQuery(
                "SELECT * FROM pm.vw_UpcomingEvents ORDER BY event_date ASC");

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetUpcomingEvents");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetOpenIssues")]
    public async Task<HttpResponseData> GetOpenIssues(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetOpenIssues function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var propertyFilter = query["propertyId"];

            var sqlQuery = "SELECT * FROM pm.vw_OpenIssues";
            if (!string.IsNullOrEmpty(propertyFilter))
            {
                sqlQuery += $" WHERE property_id = {int.Parse(propertyFilter)}";
            }
            sqlQuery += " ORDER BY issue_type, issue_id DESC";

            var result = await _db.ExecuteQuery(sqlQuery);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetOpenIssues");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetFinancialOverview")]
    public async Task<HttpResponseData> GetFinancialOverview(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetFinancialOverview function triggered");

        try
        {
            var query = System.Web.HttpUtility.ParseQueryString(req.Url.Query);
            var propertyFilter = query["propertyId"];

            var sqlQuery = "SELECT * FROM pm.vw_FinancialOverview";
            if (!string.IsNullOrEmpty(propertyFilter))
            {
                sqlQuery += $" WHERE property_id = {int.Parse(propertyFilter)}";
            }
            sqlQuery += " ORDER BY building_no, unit_number";

            var result = await _db.ExecuteQuery(sqlQuery);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetFinancialOverview");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("GetRentHistory")]
    public async Task<HttpResponseData> GetRentHistory(
        [HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequestData req)
    {
        _logger.LogInformation("GetRentHistory function triggered");

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

            var result = await _db.ExecuteStoredProcedure("pm.sp_GetRentHistory", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetRentHistory");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("AddRent")]
    public async Task<HttpResponseData> AddRent(
        [HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("AddRent function triggered");

        try
        {
            var requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            var data = JsonConvert.DeserializeObject<Dictionary<string, object>>(requestBody);

            if (data == null || !data.ContainsKey("propertyId") || !data.ContainsKey("rentAmount") || !data.ContainsKey("effectiveDate"))
            {
                var badResponse = req.CreateResponse(HttpStatusCode.BadRequest);
                await badResponse.WriteStringAsync(JsonConvert.SerializeObject(new { error = "propertyId, rentAmount, and effectiveDate are required" }));
                return badResponse;
            }

            var parameters = new Dictionary<string, object?>
            {
                { "PropertyId", data.GetValueOrDefault("propertyId") },
                { "RentYear", data.GetValueOrDefault("rentYear", DateTime.Now.Year) },
                { "RentAmount", data.GetValueOrDefault("rentAmount") },
                { "EffectiveDate", data.GetValueOrDefault("effectiveDate") },
                { "EndDate", data.GetValueOrDefault("endDate") },
                { "Notes", data.GetValueOrDefault("notes") },
                { "NewRentId", null }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_AddRent", parameters);

            var response = req.CreateResponse(HttpStatusCode.Created);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in AddRent");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }

    [Function("UpdateTaxes")]
    public async Task<HttpResponseData> UpdateTaxes(
        [HttpTrigger(AuthorizationLevel.Function, "put", "patch")] HttpRequestData req)
    {
        _logger.LogInformation("UpdateTaxes function triggered");

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
                { "MunicipalEHT", data.GetValueOrDefault("municipalEHT") },
                { "BCSpeculationTax", data.GetValueOrDefault("bcSpeculationTax") },
                { "FederalUHT", data.GetValueOrDefault("federalUHT") }
            };

            var result = await _db.ExecuteStoredProcedure("pm.sp_UpdateTaxes", parameters);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");
            await response.WriteStringAsync(result);
            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateTaxes");
            var response = req.CreateResponse(HttpStatusCode.InternalServerError);
            await response.WriteStringAsync(JsonConvert.SerializeObject(new { error = ex.Message }));
            return response;
        }
    }
}
