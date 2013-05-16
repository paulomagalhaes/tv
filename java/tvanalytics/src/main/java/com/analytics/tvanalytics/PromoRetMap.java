package com.analytics.tvanalytics;

import java.io.IOException;
import java.text.ParseException;
import java.util.Calendar;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.time.DateFormatUtils;
import org.apache.commons.lang.time.DateUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.MapWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.joda.time.DateTime;
import org.joda.time.Days;

public class PromoRetMap extends Mapper<LongWritable, Text, Text,MapWritable> {

	private static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";

	@Override
	protected void map(LongWritable key, Text value,
			org.apache.hadoop.mapreduce.Mapper.Context context)
			throws IOException, InterruptedException {
		String linha = value.toString();
		if (linha.trim().length() > 0){
			linha = linha.replaceAll("\"", "");
			//"ID","CSTATUS","CINICIO","CFIM","PINICIO","PFIM"
			String fields[] = linha.split(",");
			if (fields.length != 6) return;
			String id = fields[0];
			String cStatus = fields[1];
			String cFim = fields[3];
			String pInicio = fields[4];
			String pFim = fields[5];
			String promoEndOrNow =  StringUtils.isBlank(pFim) || pFim.trim().equals("NA") ?  "2013-05-02 00:00:00": pFim;
			Calendar calendar = Calendar.getInstance();
			int days = 0;
			try {
				// set calendar do PINICIO 
				calendar.setTime(DateUtils.parseDate(pInicio, new String[]{DATE_FORMAT}));
				// days between PINICIO and min(CFIM, DFIM)
				days = Days.daysBetween(new DateTime(calendar.getTime()), new DateTime(DateUtils.parseDate(promoEndOrNow, new String[]{DATE_FORMAT}))).getDays();
			} catch (ParseException e) {
				throw new IOException(e);
			}
			for (int i = 0; i < days; i++) {
				MapWritable map = new MapWritable();
				String date = DateFormatUtils.format(calendar, DATE_FORMAT);
				map.put(new Text("date"), new Text(date));
				map.put(new Text("status"), new Text("Active"));
				map.put(new Text("id"), new Text(id));
				context.write(new Text(date+"@"+id), map);
				calendar.add(Calendar.DATE, 1);
			}
			if (StringUtils.isNotBlank(cFim) && !cFim.trim().equals("NA")){
				MapWritable map = new MapWritable();
				String date = DateFormatUtils.format(calendar,DATE_FORMAT);
				map.put(new Text("date"), new Text(date));
				map.put(new Text("status"), new Text(cStatus));
				map.put(new Text("id"), new Text(id));
				context.write(new Text(date+"@"+id), map);
			}
		}
		 
	}
	

}
