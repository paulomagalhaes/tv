package com.analytics.tvanalytics;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import org.apache.hadoop.io.MapWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class PromoRetReducer extends
		Reducer<Text, MapWritable, Text, Text> {

	@Override
	protected void reduce(Text key, Iterable<MapWritable> values, Context context)
			throws IOException, InterruptedException {
		Map<String, Integer> result = new HashMap<String, Integer>();
		String previousId = "";
		int idCount = 1;
		for (MapWritable mapWritable : values) {
			String id = mapWritable.get(new Text("id")).toString();
			String status = mapWritable.get(new Text("status")).toString();
			if (id.equals(previousId)){
				assert status.trim().equals("Active"); // There can only be one cancel a day
				idCount++;
				String resultKey = String.valueOf(idCount);
				if (!result.containsKey(resultKey)){
					result.put(resultKey, 0);
				}
				int resultValue = result.get(resultKey);
				result.put(resultKey, resultValue++);
				
			}else{
				idCount = 1;
				if (!result.containsKey(status)){
					result.put(status, 0);
				}
				int resultValue = result.get(status);
				result.put(status, resultValue++);
			}
			previousId = id;
		}
		for (Map.Entry<String, Integer> entry : result.entrySet()) {
			StringBuilder sb = new StringBuilder();
			
//			sb.append(key).append(",");
			sb.append(entry.getKey()).append(",");
			sb.append(entry.getValue());
			context.write(key, new Text (sb.toString()));
		}
	}
}
