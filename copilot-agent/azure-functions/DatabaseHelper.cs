using Microsoft.Data.SqlClient;
using System.Data;
using Newtonsoft.Json;

namespace PropertyManagementFunctions;

public class DatabaseHelper
{
    private readonly string _connectionString;

    public DatabaseHelper(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<string> ExecuteStoredProcedure(
        string procedureName,
        Dictionary<string, object?>? parameters = null)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(procedureName, connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        // Add parameters
        if (parameters != null)
        {
            foreach (var param in parameters)
            {
                var sqlParam = command.Parameters.AddWithValue($"@{param.Key}", param.Value ?? DBNull.Value);

                // Handle OUTPUT parameters
                if (param.Key.StartsWith("New") && param.Key.EndsWith("Id"))
                {
                    sqlParam.Direction = ParameterDirection.Output;
                    sqlParam.DbType = DbType.Int32;
                }
            }
        }

        await connection.OpenAsync();

        // Execute and read results
        var results = new List<Dictionary<string, object?>>();
        using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object?>();
            for (int i = 0; i < reader.FieldCount; i++)
            {
                row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            }
            results.Add(row);
        }

        // Get output parameters
        var outputParams = new Dictionary<string, object?>();
        foreach (SqlParameter param in command.Parameters)
        {
            if (param.Direction == ParameterDirection.Output)
            {
                outputParams[param.ParameterName.TrimStart('@')] = param.Value;
            }
        }

        var response = new
        {
            success = true,
            data = results,
            outputParameters = outputParams.Count > 0 ? outputParams : null
        };

        return JsonConvert.SerializeObject(response, Formatting.Indented);
    }

    public async Task<string> ExecuteQuery(string query)
    {
        using var connection = new SqlConnection(_connectionString);
        using var command = new SqlCommand(query, connection);

        await connection.OpenAsync();

        var results = new List<Dictionary<string, object?>>();
        using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            var row = new Dictionary<string, object?>();
            for (int i = 0; i < reader.FieldCount; i++)
            {
                row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
            }
            results.Add(row);
        }

        var response = new
        {
            success = true,
            data = results
        };

        return JsonConvert.SerializeObject(response, Formatting.Indented);
    }
}
