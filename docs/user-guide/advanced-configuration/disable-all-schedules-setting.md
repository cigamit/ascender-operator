#### Disable All Schedules

With `disable_all_schedules`, you can pass the value for `DISABLE_ALL_SCHEDULES` to `/etc/tower/settings.py`.

Set this to `True` when restoring into disaster recovery so schedules stay disabled after the application starts.  You are still able to manually run and test jobs, but any scheduled jobs 


| Name                  | Description               | Default |
| --------------------- | ------------------------- | ------- |
| disable_all_schedules | Disable All Schedules     | False   |

Example configuration of the `disable_all_schedules` setting:

```yaml
  spec:
    disable_all_schedules: 'True'
```