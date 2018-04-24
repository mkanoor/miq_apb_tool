from ansible.plugins.action import ActionBase
import yaml
import time

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):

        if task_vars is None:
            task_vars = dict()

        result = super(ActionModule, self).run(tmp, task_vars)

        delay = self._task.args.get('delay', 30)
        retries = self._task.args.get('retries', 10)

        config_map_args = {}
        config_map_args['namespace'] = self._task.args.get('namespace')
        config_map_args['name'] = self._task.args.get('name')

        uri_module_args = {}
        uri_module_args['url'] = self._task.args.get('url')
        uri_module_args['user'] = self._task.args.get('user')
        uri_module_args['password'] = self._task.args.get('password')
        uri_module_args['validate_certs'] = self._task.args.get('validate_certs', True)
        uri_module_args['method'] = 'GET'
        uri_module_args['force_basic_auth'] = 'yes'
        uri_module_args['headers'] = { 'Content-Type': 'application/json'}
        uri_module_args['status_code'] = 200

        for i in range(1, retries):
            result['uri_result'] = self._execute_module(module_name='uri',
                    module_args=uri_module_args,
                    task_vars=task_vars, tmp=tmp)

            status_data = {'address': 'Elm Street', 'name': 'Freddy Kreuger', 'counter': i}
            config_map_args['data'] = {'status': yaml.dump(status_data, default_flow_style=False)}

            result['config_result'] = self._execute_module(module_name='k8s_v1_config_map',
                    module_args=config_map_args,
                    task_vars=task_vars, tmp=tmp)

            if result['uri_result']['status'] != 200:
               break
            time.sleep(delay)

        result['changed'] = True

        return result
