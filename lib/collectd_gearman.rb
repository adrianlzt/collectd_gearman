require "collectd_gearman/version"
require 'pp'

module CollectdGearman
  # severity time host 
  # plugin plugininstance(opt) 
  # type typeinstance(opt) 
  # datasource ("value" en caso de que no halla uno definido)
  # currentvalue 
  # warningmin warningmax failuremin failuremax (todos estos pueden ser "nan")
  #
  # send_gearman --server=127.0.0.1 --encryption=yes --key=key --host="client.com" --service="Check_nuevo" --message="CRITICAL - alerrrrta | size=100;200;300;0" -r=2
  
  def send_gearman(server,key,host,service,message,severity)
    case severity
    when "FAILURE"
      return_code = 2
    when "WARNING"
      return_code = 1
    when "OKAY"
      return_code = 0
    else
      return_code = 3
    end
  
    system("/usr/bin/send_gearman --server=#{server} --encryption=yes --key=#{key} --host=#{host} --service=#{service} --message=#{message} -r=#{return_code}")
  end
  
  # Read conf data (fails if doesn't exists)
  # Debe leer de algun lado donde debe enviar el check pasivo (icinga_host) y la clave para que le acepte el servidor gearman
  
  # Read stdin data
  data = {}
  ARGF.each do |line|
    if line =~ /^[a-zA-Z]+: .*/
      data.merge!({line.split(": ").first => line.split(": ").last.strip})
    else
      data.merge!(message: line.strip)
    end
  end
  
  # DataSource = value is the same as nothing
  data.delete("DataSource") if data["DataSource"] == "value"
  pp data
  
  puts "icinga: #{icinga_host}"
  
  # Send passive checks to all posible services
  # Plugin-Instance.Type-Instance.DataSource (si DataSource = value, no se pone)
  # Plugin-Instance.Type-Instance
  # Plugin-Instance.Type.DataSource
  # Plugin-Instance.Type
  # Plugin.Type-Instance.DataSource
  # Plugin.Type-Instance
  # Plugin.Type.DataSource
  # Plugin.Type
  
  if data["PluginInstance"] and data["TypeInstance"] and data["DataSource"]
    puts "#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}-#{data["TypeInstance"]}.#{data["DataSource"]}"
  end
  
  if data["PluginInstance"] and data["TypeInstance"]
    puts "#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}-#{data["TypeInstance"]}"
  end
  
  if data["PluginInstance"] and data["DataSource"]
    puts "#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}.#{data["DataSource"]}"
  end
  
  if data["PluginInstance"]
    puts "#{data["Plugin"]}-#{data["PluginInstance"]}.#{data["Type"]}"
  end
  
  if data["TypeInstance"] and data["DataSource"]
    puts "#{data["Plugin"]}.#{data["Type"]}-#{data["TypeInstance"]}.#{data["DataSource"]}"
  end
  
  if data["TypeInstance"]
    puts "#{data["Plugin"]}.#{data["Type"]}-#{data["TypeInstance"]}"
  end
  
  puts "#{data["Plugin"]}.#{data["Type"]}"
  
  
   
  
  #
  # Como sabemos a que check pasivo debe enviarse (y que este exista!)
  # Debemos interpretar el threshold de los checks definidos.
  #
  # Dentro de cada threshold siempre metemos el <Plugin NOMBRE>
  # Dentro de plugin puede haber, o no, un Instance.
  # Dentro de cada plugin puede haber varios type
  #
  # Caso 1: plugin sin instance y con un type => 
  # Caso 2: plugin sin instance y con varios types
  # Caso 3: plugin con instance y con un type
  # Caso 4: plugin con instance y con varios types
  # Caso 5: mismo plugin dos veces con distintos instances y distintos types
  #
  # Plugin-Instance.Type-Instance.DataSource
  #
  # Problema, definimos un check generico para todos los discos, pero cuando nos llame threshold nos dira toda la info de instance, type instance, datasource etc.
  # Nosotros, en este caso, queremos que todos los checks de disco se envien al mismo check pasivo.
  #
  # Tendremos que hacer una jerarquia, buscando primero si hay un plugin-threshold definido para este Plugin-Instance.Type-Instance.DataSource determinado
  # Si no existe:
  #   - mirar si hay un Plugin-Instance.Type-Instance
  #   - o mirar si hay un Plugin-Instance.Type-*.DataSource 
  #   - o mirar si hay un Plugin-*.Type-Instance.DataSource 
  #   - o ...
  #
  #
  # Mejor, enviar alarmas a todos los checks posibles (se quejara nagios de recibir checks que no conoce?)
  # Enviar a (host incluido en todas):
  # Plugin-Instance.Type-Instance.DataSource (si DataSource = value, no se pone)
  # Plugin-Instance.Type-Instance
  # Plugin-Instance.Type.DataSource
  # Plugin-Instance.Type
  # Plugin.Type-Instance.DataSource
  # Plugin.Type-Instance
  # Plugin.Type.DataSource
  # Plugin.Type
  #
  #
  # Ejemplo para load:
  # Salta alarma en load.load.shortterm
  # Se envía a:
  # load.load
  # load.load.shortterm
  #
  # Ejemplo para disk:
  # Salta alarma en Plugin: disk PluginInstance: sda5 Type: disk_octets DataSource: read
  # Se envía alarma a:
  # Disk-sda5.disk_octets.read
  # Disk-sda5.disk_octets
  # Disk.disk_octets.read
  # Disk.disk_octets
  #
  # Ejemplo para df:
  # Salta: Plugin: df PluginInstance: root Type: df_complex TypeInstance: used DataSource: value
  # Se envía alarma a:
  # df-root.df_complex-used
  # df-root.df_complex
  # df.df_complex-used
  # df.df_complex
  #
  #
end
